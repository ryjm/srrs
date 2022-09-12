import { CloudDownload } from '@mui/icons-material';
import { Button, IconButton, Popover, Stack, TextField } from '@mui/material';
import { Box } from '@mui/system';
import { bindPopover, bindTrigger, usePopupState } from 'material-ui-popup-state/hooks';
import React, { ChangeEventHandler, useState } from 'react';
import { ChangeEvent } from 'react';
import SeerApi from '~/types/SeerApi';

type ImportProps = { api: SeerApi, who: String, stack: String }

const Import = (api) => {

  const handleWhoChange = (event: ChangeEvent<HTMLInputElement>) => {
    setWho(event.target.value);
  };
  const handleStackChange = (event: ChangeEvent<HTMLInputElement>) => {
    setStack(event.target.value);
  };
  const importStack = (props: ImportProps) => {
      const data = {
        import: {
          who: props.who,
          stack: props.stack,
        },
      };
  
      props.api.action("seer", "seer-action", data);
    }
  
    const [who, setWho] = useState('');
    const [stack, setStack] = useState(null);
    const popupState = usePopupState({
      variant: 'popover',
      popupId: 'import',
    })
    return (
      <div>
      <Button color='primary' {...bindTrigger(popupState)}>
        <CloudDownload />
      </Button>
      <Popover
        {...bindPopover(popupState)}

        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'center',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
      >
          <Box
        sx={{
          bgcolor: 'background.paper',
          boxShadow: 1,
          borderRadius: 2,
          p: 2,
          minWidth: 300,
        }}>
        <Stack spacing={2} >
          
    <TextField
          size="small"
          placeholder="@p"
          onChange={handleWhoChange}
        />
        <TextField
          size="small"
          placeholder="stack name"
          onChange={handleStackChange}
        />
        <Button
          color="secondary"
          variant="contained"
          onClick={(e) => importStack({ api, who, stack })}
        >
          import
        </Button>
        </Stack>
        </Box>
</Popover>
</div>)

      }

export default Import