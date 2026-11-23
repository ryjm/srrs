//! The engine ABI of RWKV.md. A buffer from `alloc` belongs to the call it
//! is passed to, which frees it.

use std::cell::RefCell;

use crate::seer;
use crate::Engine;

thread_local! {
    static ENGINE: RefCell<Option<Engine>> = const { RefCell::new(None) };
    static OUTPUT: RefCell<Vec<u8>> = const { RefCell::new(Vec::new()) };
}

unsafe fn take(ptr: i32, len: i32) -> Box<[u8]> {
    let slice = std::ptr::slice_from_raw_parts_mut(ptr as usize as *mut u8, len as usize);
    unsafe { Box::from_raw(slice) }
}

#[no_mangle]
pub extern "C" fn alloc(len: i32) -> i32 {
    let buffer = vec![0u8; len.max(0) as usize].into_boxed_slice();
    Box::into_raw(buffer) as *mut u8 as usize as i32
}

/// # Safety
/// `ptr` and `len` come from one `alloc` call.
#[no_mangle]
pub unsafe extern "C" fn load_weights(ptr: i32, len: i32) -> i32 {
    let weights = unsafe { take(ptr, len) };
    match Engine::load(&weights) {
        Ok(engine) => {
            ENGINE.with(|slot| *slot.borrow_mut() = Some(engine));
            0
        }
        Err(_) => 1,
    }
}

/// # Safety
/// `ptr` and `len` come from one `alloc` call.
#[no_mangle]
pub unsafe extern "C" fn predict(ptr: i32, len: i32) -> i32 {
    let input = unsafe { take(ptr, len) };
    let output = ENGINE.with(|slot| match slot.borrow_mut().as_mut() {
        Some(engine) => seer::predict(engine, &input).ok(),
        None => None,
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
