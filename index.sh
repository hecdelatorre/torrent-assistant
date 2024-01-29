#!/bin/bash

# Function to check and create folder structure
check_folder_structure() {
    local db_folder="$HOME/.db-torrent"
    local db_file="$db_folder/data.db"

    # Check if ".db-torrent" folder exists, if not, create it
    if [ ! -d "$db_folder" ]; then
        mkdir -p "$db_folder"
    fi

    # Check if database file exists, if not, create it
    if [ ! -f "$db_file" ]; then
        sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS downloads (
    id INTEGER PRIMARY KEY,
    directory TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY,
    directory TEXT NOT NULL
);
EOF
    fi
}

# Function to add a download directory
add_download_directory() {
    local directory
    read -p "Enter download directory: " directory

    # Add directory to the 'downloads' table in the database
    sqlite3 "$HOME/.db-torrent/data.db" "INSERT INTO downloads (directory) VALUES ('$directory');"
    echo "Download directory added successfully."
}

# Function to add a session directory
add_session_directory() {
    local directory
    read -p "Enter session directory: " directory

    # Add directory to the 'sessions' table in the database
    sqlite3 "$HOME/.db-torrent/data.db" "INSERT INTO sessions (directory) VALUES ('$directory');"
    echo "Session directory added successfully."
}

# Directory Manager
directory_manager() {
    clear
    echo "Directory Manager"
    echo "1. Add download directory"
    echo "2. Add session directory"
    echo "3. Exit"

    read -p "Select an option: " choice

    case $choice in
        1) add_download_directory ;;
        2) add_session_directory ;;
        3) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Torrents Executor
torrents_executor() {
    echo "Torrents Executor"
    # Implement the logic for running torrents here
    # Example: xterm -e rtorrent ...
}

# Main menu
while true; do
    clear
    echo "Main Menu"
    echo "1. Directory manager"
    echo "2. Torrents Executor"
    echo "3. Exit"

    read -p "Select an option: " choice

    case $choice in
        1) check_folder_structure && directory_manager ;;
        2) torrents_executor ;;
        3) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac

    read -n 1 -s -r -p "Press any key to continue..."
done
