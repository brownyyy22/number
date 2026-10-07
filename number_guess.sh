#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

echo "Enter your username:"
read -r USERNAME
USERNAME_SQL=${USERNAME//\'/\'\'}

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME_SQL';")
if [[ -z "$USER_ID" ]]; then
  USER_ID=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME_SQL') RETURNING user_id;")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID;")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $USER_ID;")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$((1 + RANDOM % 1000))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
read -r GUESS

while true; do
  if ! [[ "$GUESS" =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read -r GUESS
    continue
  fi

  if [[ "$GUESS" == -* ]]; then
    GUESS_NUMBER=$((-10#${GUESS#-}))
  else
    GUESS_NUMBER=$((10#$GUESS))
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
  if [[ "$GUESS_NUMBER" -eq "$SECRET_NUMBER" ]]; then
    break
  elif [[ "$GUESS_NUMBER" -gt "$SECRET_NUMBER" ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
  read -r GUESS
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO games (user_id, number_of_guesses) VALUES ($USER_ID, $NUMBER_OF_GUESSES);" > /dev/null
