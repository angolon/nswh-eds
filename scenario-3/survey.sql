PRAGMA foreign_keys = ON;

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

CREATE VIEW ResponseOverview AS
SELECT
  SR.userName,
  SR.userEmail,
  ResponseResults.surveyResponseId,
  S.id AS surveyId,
  S.name AS surveyName,
  ResponseResults.numCorrect,
  ResponseResults.numQuestions,
  (ResponseResults.numCorrect / ResponseResults.numQuestions) AS percentageCorrect
FROM
  Survey AS S
  INNER JOIN SurveyResponse AS SR
    ON SR.surveyId = S.id
  INNER JOIN (
    SELECT
      surveyResponseId,
      SUM(numQuestions) as numQuestions,
      SUM(numCorrect) as numCorrect
    FROM (
        SELECT
          R.surveyResponseId,
          COUNT(Q.questionId) as numQuestions,
          SUM(
            CASE R.response
              WHEN Q.answer THEN 1
              ELSE 0
            END
          ) AS numCorrect
        FROM
          FreeFormResponse as R
          INNER JOIN FreeFormQuestion AS Q
            on R.questionId = Q.questionId
        GROUP BY R.surveyResponseId
      UNION ALL
        SELECT
          R.surveyResponseId,
          COUNT(Q.questionId) as numQuestions,
          SUM(
            CASE R.response
              WHEN Q.answer THEN 1
              ELSE 0
            END
          ) AS numCorrect
        FROM
          BinaryResponse as R
          INNER JOIN BinaryQuestion AS Q
            on R.questionId = Q.questionId
        GROUP BY R.surveyResponseId
      UNION ALL
        SELECT
          R.surveyResponseId,
          COUNT(R.response) as numQuestions,
          SUM(
            CASE
              WHEN R.Response IS Q.optionId THEN 1
              ELSE 0
            END
          ) AS numCorrect
        FROM
          MultipleChoiceResponse as R
          LEFT JOIN MultipleChoiceAnswer AS Q
            on R.response = Q.optionId
        GROUP BY R.surveyResponseId
    ) AS CorrectAnswerCounts
    GROUP BY CorrectAnswerCounts.surveyResponseId
  ) AS ResponseResults
    ON ResponseResults.surveyResponseId = SR.id
;

-- Forces the interpreter to validate that all the joins/column names are
-- correct and happy.
SELECT * FROM ResponseOverview;
