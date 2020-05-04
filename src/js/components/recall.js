import React, { Component } from 'react';
import classnames from 'classnames';
import Choices from 'react-choices'

export class Recall extends Component {
    constructor(props) {
        super(props);
    }
    
    render() {
        if (!this.props.enabled) {
            return null;
        } else if (this.props.mode === 'view') {
            return (

                <div className="flex-col fr">

                    <p className="label-regular gray-50 pointer tr b"
                        onClick={this.props.gradeItem}>
                        Grade
            </p>

                    <p className="label-regular gray-50 pointer tr b"
                        onClick={this.props.editItem}>
                        Edit
            </p>
                    <p className="label-regular red pointer tr b"
                        onClick={this.props.deleteItem}>
                        Delete
            </p>
                    <p className="label-regular gray-50 pointer tr b"
                        onClick={this.props.toggleAdvanced}>
                        Advanced
            </p>
                </div>
            );
        } else if (this.props.mode === 'edit') {
            return (
                <div className="flex-col fr">
                    <p className="pointer"
                        onClick={this.props.saveItem}>
                        -> Save
            </p>
                    <p className="pointer"
                        onClick={this.props.deleteItem}>
                        Delete item
            </p>
                </div>
            );
        } else if (this.props.mode === 'grade') {
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
                        defaultValue="again"
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
                                    <p className="pointer"
                                        onClick={this.props.saveGrade}>
                                        ->  Save Grade
                                    </p>
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
                                                    this.props.setGrade(state.value);
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
        } else if (this.props.mode === 'advanced') {
            let ease = `ease: ${this.props.learn.ease}`;
            let interval = `interval: ${this.props.learn.interval}`;
            let box = `box: ${this.props.learn.box}`;
            let backString = `<- Back`

            return (
                <div className="body-regular flex-col fr">
                    <p className="pointer"
                        onClick={this.props.toggleAdvanced}>
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