#!/bin/bash

set -e

setupSSH() {
  local SSH_PATH="$HOME/.ssh"

  mkdir -p "$SSH_PATH"
  touch "$SSH_PATH/known_hosts"

  echo "$INPUT_KEY" > "$SSH_PATH/deploy_key"

  chmod 700 "$SSH_PATH"
  chmod 600 "$SSH_PATH/known_hosts"
  chmod 600 "$SSH_PATH/deploy_key"

  eval $(ssh-agent)
  ssh-add "$SSH_PATH/deploy_key"

  ssh-keyscan -t rsa $INPUT_BOARD_HOST >> "$SSH_PATH/known_hosts"
}

executeSSH() {
  local LINES=$1
  local COMMAND=""

  # holds all commands separated by semi-colon
  local COMMANDS=""

  # this while read each commands in line and
  # evaluate each line agains all environment variables
  while IFS= read -r LINE; do
    LINE=$(eval 'echo "$LINE"')
    LINE=$(eval echo "$LINE")
    COMMAND=$(echo $LINE)

    if [ -z "$COMMANDS" ]; then
      COMMANDS="$COMMAND"
    else
      COMMANDS="$COMMANDS;$COMMAND"
    fi
  done <<< $LINES

  echo "ssh -o StrictHostKeyChecking=no -p ${INPUT_BOARD_PORT:-22} -A -tt $INPUT_BOARD_USER@$INPUT_BOARD_HOST sh \"$INPUT_BOARD_SCRIPT $INPUT_DST_USER $INPUT_DST_HOST $INPUT_FILE_NAME $INPUT_DST_FILE_PATH $COMMANDS\""
  #ssh -o StrictHostKeyChecking=no -p ${INPUT_PORT:-22} $INPUT_USER@$INPUT_HOST "$COMMANDS"
  ssh -o StrictHostKeyChecking=no -p ${INPUT_BOARD_PORT:-22} -A -tt $INPUT_BOARD_USER@$INPUT_BOARD_HOST sh "$INPUT_BOARD_SCRIPT $INPUT_DST_USER $INPUT_DST_HOST $INPUT_FILE_NAME $INPUT_DST_FILE_PATH $COMMANDS"
}

executeSCP() {
  local LINES=$1
  local COMMAND=

  # this while read each commands in line and
  # evaluate each line agains all environment variables
  while IFS= read -r LINE; do
    LINE=$(eval 'echo "$LINE"')
    LINE=$(eval echo "$LINE")
    COMMAND=$(echo $LINE)

    # scp will fail if COMMAND is empty, this condition protects scp
    #if [[ $COMMAND = *[!\ ]* ]]; then
      echo "scp -r -o StrictHostKeyChecking=no $INPUT_FILE_NAME $INPUT_BOARD_USER@$INPUT_BOARD_HOST:$INPUT_BOARD_FILE_PATH"
      scp -r -o StrictHostKeyChecking=no $INPUT_FILE_NAME $INPUT_BOARD_USER@$INPUT_BOARD_HOST:$INPUT_BOARD_FILE_PATH
    #fi
  done <<< $LINES
}

setupSSH
echo "+++++++++++++++++++RUNNING BEFORE SSH+++++++++++++++++++"
#executeSSH "$INPUT_SSH_BEFORE"
echo "+++++++++++++++++++RUNNING BEFORE SSH+++++++++++++++++++"
echo "+++++++++++++++++++RUNNING SCP+++++++++++++++++++"
executeSCP
echo "+++++++++++++++++++RUNNING SCP+++++++++++++++++++"
echo "+++++++++++++++++++RUNNING AFTER SSH+++++++++++++++++++"
executeSSH "$INPUT_SSH_AFTER"
echo "+++++++++++++++++++RUNNING AFTER SSH+++++++++++++++++++"
