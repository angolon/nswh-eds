CREATE TABLE Survey (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE Question (
    id INTEGER PRIMARY KEY,
    surveyId INTEGER NOT NULL,
    questionText TEXT NOT NULL,
    FOREIGN KEY (surveyId) REFERENCES Survey (id)
);

CREATE TABLE FreeFormQuestion (
    questionId INTEGER PRIMARY KEY,
    answer TEXT NOT NULL,
    FOREIGN KEY (questionId) REFERENCES Question (id)
);

CREATE TABLE BinaryQuestion (
    questionId INTEGER PRIMARY KEY,
    answer BOOLEAN NOT NULL,
    FOREIGN KEY (questionId) REFERENCES Question (id)
);

CREATE TABLE MultipleChoiceOption (
    optionId INTEGER PRIMARY KEY,
    questionId INTEGER NOT NULL,
    optionText TEXT NOT NULL,
    FOREIGN KEY (questionId) REFERENCES Question (id)
);

CREATE TABLE MultipleChoiceAnswer (
    questionId INTEGER PRIMARY KEY,
    optionId INTEGER NOT NULL,
    FOREIGN KEY (questionId, optionId) REFERENCES MultipleChoiceOption (questionId, optionId)
);

CREATE TABLE SurveyResponse (
    id INTEGER PRIMARY KEY,
    surveyId INTEGER NOT NULL,
    userName TEXT NOT NULL,
    userEMail TEXT NOT NULL,
    FOREIGN KEY (surveyId) REFERENCES Survey (id)
);

CREATE TABLE FreeFormResponse (
    surveyResponseId INTEGER NOT NULL,
    questionId INTEGER NOT NULL,
    response TEXT NOT NULL,
    PRIMARY KEY (surveyResponseId, questionId),
    FOREIGN KEY (surveyResponseId) REFERENCES SurveyResponse (id),
    FOREIGN KEY (questionId) REFERENCES FreeFormQuestion (questionId)
);

CREATE TABLE BinaryResponse (
    surveyResponseId INTEGER NOT NULL,
    questionId INTEGER NOT NULL,
    response BOOLEAN NOT NULL,
    PRIMARY KEY (surveyResponseId, questionId),
    FOREIGN KEY (surveyResponseId) REFERENCES SurveyResponse (id),
    FOREIGN KEY (questionId) REFERENCES BinaryQuestion (questionId)
);

CREATE TABLE MultipleChoiceResponse (
    surveyResponseId INTEGER NOT NULL,
    response INTEGER NOT NULL,
    PRIMARY KEY (surveyResponseId, response),
    FOREIGN KEY (surveyResponseId) REFERENCES SurveyResponse (id),
    FOREIGN KEY (response) REFERENCES MultipleChoiceOption (optionId)
);

