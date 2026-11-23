//! The engine ABI of RWKV.md. A buffer from `alloc` belongs to the one call
//! it is passed to, with the same length, which frees it. Lengths outside
//! `0..=i32::MAX` and null pointers are refused before any ownership is
//! taken. `predict` output is borrowed until the next `predict` or the end
//! of the instance.

use std::cell::RefCell;

use crate::seer;
use crate::Engine;

thread_local! {
    static ENGINE: RefCell<Option<Engine>> = const { RefCell::new(None) };
    static OUTPUT: RefCell<Vec<u8>> = const { RefCell::new(Vec::new()) };
}

/// # Safety
/// `ptr` and `len` come from one `alloc` call not yet passed to `take`.
unsafe fn take(ptr: i32, len: i32) -> Option<Box<[u8]>> {
    let len = usize::try_from(len).ok()?;
    if ptr == 0 {
        return None;
    }
    let slice = std::ptr::slice_from_raw_parts_mut(ptr as usize as *mut u8, len);
    Some(unsafe { Box::from_raw(slice) })
}

/// A pointer to `len` zeroed bytes, or 0 when `len` is negative or the
/// memory cannot grow to hold it.
#[no_mangle]
pub extern "C" fn alloc(len: i32) -> i32 {
    let Ok(len) = usize::try_from(len) else {
        return 0;
    };
    let mut buffer = Vec::new();
    if buffer.try_reserve_exact(len).is_err() {
        return 0;
    }
    buffer.resize(len, 0u8);
    Box::into_raw(buffer.into_boxed_slice()) as *mut u8 as usize as i32
}

/// # Safety
/// `ptr` and `len` come from one `alloc` call not passed to any other call.
#[no_mangle]
pub unsafe extern "C" fn load_weights(ptr: i32, len: i32) -> i32 {
    let Some(weights) = (unsafe { take(ptr, len) }) else {
        return 1;
    };
    match Engine::load(&weights) {
        Ok(engine) => {
            ENGINE.with(|slot| *slot.borrow_mut() = Some(engine));
            0
        }
        Err(_) => 1,
    }
}

/// # Safety
/// `ptr` and `len` come from one `alloc` call not passed to any other call.
#[no_mangle]
pub unsafe extern "C" fn predict(ptr: i32, len: i32) -> i32 {
    let output = unsafe { take(ptr, len) }.and_then(|input| {
        ENGINE.with(|slot| match slot.borrow_mut().as_mut() {
            Some(engine) => seer::predict(engine, &input).ok(),
            None => None,
        })
    });
    OUTPUT.with(|slot| {
        let mut slot = slot.borrow_mut();
        *slot = output.unwrap_or_default();
        if slot.is_empty() {
            0
        } else {
            slot.as_ptr() as usize as i32
        }
    })
}

#[no_mangle]
pub extern "C" fn output_len() -> i32 {
    OUTPUT.with(|slot| slot.borrow().len() as i32)
}
