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
CREATE TABLE IF NOT EXISTS directories (
    id INTEGER PRIMARY KEY,
    download_directory TEXT NOT NULL,
    session_directory TEXT NOT NULL
);
EOF
    fi
}

# Function to add download and session directories
add_directories() {
    local download_directory
    local session_directory

    read -p "Enter download directory: " download_directory
    read -p "Enter session directory: " session_directory

    # Add directories to the 'directories' table in the database
    sqlite3 "$HOME/.db-torrent/data.db" "INSERT INTO directories (download_directory, session_directory) VALUES ('$download_directory', '$session_directory');"
    echo "Directories added successfully."
}

# Main menu
while true; do
    clear
    echo "Main Menu"
    echo "1. Add download and session directories"
    echo "2. Torrents Executor"
    echo "3. Exit"

    read -p "Select an option: " choice

    case $choice in
        1) check_folder_structure && add_directories ;;
        2) # Implement Torrents Executor logic here ;;
        3) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac

    read -n 1 -s -r -p "Press any key to continue..."
done
