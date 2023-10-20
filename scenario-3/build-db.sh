#!/bin/sh
rm -f survey.db
sqlite3 survey.db < survey.sql
