import { Box, Button, Chip, Stack } from "@mui/joy";
import classnames from "classnames-es";
import * as React from "react";
import Choices from "react-choices";

export class Recall extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const { props } = this;
    if (!props.enabled && props.mode === "view") {
      const modifyButtonClasses =
        "mt4 db f9 ba pa2 white-d bg-gray0-d b--black b--gray2-d pointer mb1";
      return (
        <Box>
          <Choices
            name="recall_grade"
            availableStates={[
              { value: "again" },
              { value: "hard" },
              { value: "good" },
              { value: "easy" },
            ]}
            defaultValue="again"
          >
            {({ name, states, selectedValue, setValue, hoverValue }) => (
              <div className="choices fr">
                <Stack spacing={1} className="choices__items">
                  {states.map((state, idx) => (
                    <Button
                      variant="outlined"
                      key={`choice-${idx}`}
                      id={`choice-${state.value}`}
                      tabIndex={state.selected ? 0 : -1}
                      className={classnames(
                        "choice",
                        state.inputClassName,
                        {
                          "bg-gray5": state.hovered,
                        },
                        modifyButtonClasses
                      )}
                      onMouseOver={hoverValue.bind(null, state.value)}
                      onClick={() => {
                        setValue(state.value);
                        props.setGrade(state.value);
                        props.saveGrade(state.value);
                      }}
                    >
                      {state.label}
                    </Button>
                  ))}
                </Stack>
              </div>
            )}
          </Choices>
        </Box>
      );
    } else if (props.mode === "view") {
      return (
        <Box>
          <Stack spacing={1}>
            <Button variant="outlined" onClick={props.gradeItem}>
              grade
            </Button>
            <Button variant="outlined" onClick={props.editItem}>
              edit
            </Button>
            <Button variant="solid" color="danger" onClick={props.deleteItem}>
              delete
            </Button>
            <Button variant="soft" color="info" onClick={props.toggleAdvanced}>
              details
            </Button>
          </Stack>
        </Box>
      );
    } else if (props.mode === "edit") {
      return (
        <Box sx={{ display: "flex", float: "right" }}>
          <Button variant="soft" color="neutral" onClick={props.saveItem}>
            Save
          </Button>
          <Button variant="soft" color="danger" onClick={props.deleteItem}>
            Delete
          </Button>
        </Box>
      );
    } else if (props.mode === "grade" || props.mode === "review") {
      const modifyButtonClasses =
        "mt4 db f9 ba pa2 white-d bg-gray0-d b--black b--gray2-d pointer mb1";
      return (
        <Box
          sx={{
            display: "flex",
            float: "right",
          }}
        >
          <Choices
            name="recall_grade"
            availableStates={[
              { value: "again" },
              { value: "hard" },
              { value: "good" },
              { value: "easy" },
            ]}
            defaultValue="again"
          >
            {({ name, states, selectedValue, setValue, hoverValue }) => (
              <div className="choices fr">
                <Stack spacing={1} className="choices__items">
                  {states.map((state, idx) => (
                    <Button
                      variant="outlined"
                      key={`choice-${idx}`}
                      id={`choice-${state.value}`}
                      tabIndex={state.selected ? 0 : -1}
                      className={classnames(
                        "choice",
                        state.inputClassName,
                        {
                          "bg-gray5": state.hovered,
                        },
                        modifyButtonClasses
                      )}
                      onMouseOver={hoverValue.bind(null, state.value)}
                      onClick={() => {
                        setValue(state.value);
                        props.setGrade(state.value);
                        props.saveGrade(state.value);
                      }}
                    >
                      {state.label}
                    </Button>
                  ))}
                </Stack>
              </div>
            )}
          </Choices>
        </Box>
      );
    } else if (props.mode === "advanced") {
      const ease = `ease: ${props.learn.ease}`;
      const interval = `interval: ${props.learn.interval}`;
      const box = `box: ${props.learn.box}`;
      const backString = "<- Back";

      return (
        <Stack spacing={1}>
          <Button variant="soft" color="neutral" onClick={props.toggleAdvanced}>
            {backString}
          </Button>
          <Chip>{ease}</Chip>
          <Chip>{interval}</Chip>
          <Chip>{box}</Chip>
        </Stack>
      );
    }
  }
}
