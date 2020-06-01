import React, { Component } from 'react';
import classnames from 'classnames';
import Choices from 'react-choices'

export class Recall extends Component {
    constructor(props) {
        super(props);
    }
    
    render() {
        const { props, state} = this;
        if (!props.enabled && (props.mode === 'view')) {
            let modifyButtonClasses = "mt4 db f9 ba pa2 white-d bg-gray0-d b--black b--gray2-d pointer mb1";
            return (
                <div className="flex fr">

                    <Choices
                        name="recall_grade"
                        availableStates={[
                            { value: 'again' },
                            { value: 'hard' },
                            { value: 'good' },
                            { value: 'easy' }
                        ]}
                        defaultValue='again'
                    >
                        {({
                            name,
                            states,
                            selectedValue,
                            setValue,
                            hoverValue
                        }) => (

                                <div
                                    className="choices fr"
                                >
                                    <div className="choices__items">
                                        {states.map((state, idx) => (
                                            <button
                                                key={`choice-${idx}`}
                                                id={`choice-${state.value}`}
                                                tabIndex={state.selected ? 0 : -1}
                                                className={classnames('choice', state.inputClassName, {
                                                    'choice--focused': state.focused,
                                                    'bg-gray5': state.hovered,
                                                    'bg-light-green': state.selected
                                                }, modifyButtonClasses)}
                                                onMouseOver={hoverValue.bind(null, state.value)}
                                                onClick={() => {
                                                    setValue(state.value);
                                                    props.setGrade(state.value);
                                                    props.saveGrade(state.value);
                                                }
                                                }
                                            >
                                                {state.label}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            )}
                    </Choices>
                </div>
            )
        } else if (props.mode === 'view') {
            return (

                <div className="flex-col fr">

                    <p className="label-regular gray-50 pointer tr b"
                        onClick={props.gradeItem}>
                        Grade
            </p>

                    <p className="label-regular gray-50 pointer tr b"
                        onClick={props.editItem}>
                        Edit
            </p>
                    <p className="label-regular red pointer tr b"
                        onClick={props.deleteItem}>
                        Delete
            </p>
                    <p className="label-regular gray-50 pointer tr b"
                        onClick={props.toggleAdvanced}>
                        Advanced
            </p>
                </div>
            );
        } else if (props.mode === 'edit') {
            return (
                <div className="flex-col fr">
                    <p className="pointer"
                        onClick={props.saveItem}>
                        -> Save
            </p>
                    <p className="pointer"
                        onClick={props.deleteItem}>
                        Delete item
            </p>
                </div>
            );
        } else if (props.mode === 'grade' || props.mode === 'review') {
            let modifyButtonClasses = "mt4 db f9 ba pa2 white-d bg-gray0-d b--black b--gray2-d pointer mb1";
            return (
                <div className="flex fr">

                    <Choices
                        name="recall_grade"
                        availableStates={[
                            { value: 'again' },
                            { value: 'hard' },
                            { value: 'good' },
                            { value: 'easy' }
                        ]}
                        defaultValue='again'
                    >
                        {({
                            name,
                            states,
                            selectedValue,
                            setValue,
                            hoverValue
                        }) => (

                                <div
                                    className="choices fr"
                                >
                                    <div className="choices__items">
                                        {states.map((state, idx) => (
                                            <button
                                                key={`choice-${idx}`}
                                                id={`choice-${state.value}`}
                                                tabIndex={state.selected ? 0 : -1}
                                                className={classnames('choice', state.inputClassName, {
                                                    'choice--focused': state.focused,
                                                    'bg-gray5': state.hovered,
                                                    'bg-light-green': state.selected
                                                }, modifyButtonClasses)}
                                                onMouseOver={hoverValue.bind(null, state.value)}
                                                onClick={() => {
                                                    setValue(state.value);
                                                    props.setGrade(state.value);
                                                    props.saveGrade(state.value);
                                                }
                                                }
                                            >
                                                {state.label}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            )}
                    </Choices>
                </div>
            );
        } else if (props.mode === 'advanced') {
            let ease = `ease: ${props.learn.ease}`;
            let interval = `interval: ${props.learn.interval}`;
            let box = `box: ${props.learn.box}`;
            let backString = `<- Back`

            return (
                <div className="body-regular flex-col fr">
                    <p className="pointer"
                        onClick={props.toggleAdvanced}>
                        {backString}
                    </p>
                    <p className="label-small gray-50">{ease}</p>
                    <p className="label-small gray-50">{interval}</p>
                    <p className="label-small gray-50">{box}</p>
                </div>
            );
        }

    }
}