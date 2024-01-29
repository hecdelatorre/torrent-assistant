#!/bin/bash

db_dir="$HOME/.db-torrent"
db_file="$db_dir/data.db"

# Function to initialize directory structure and SQLite database
initialize_db() {
    # Check and create .db-torrent directory if not exists
    if [ ! -d "$db_dir" ]; then
        mkdir "$db_dir"
    fi

    # Check and create data.db if not exists
    if [ ! -f "$db_file" ]; then
        sqlite3 "$db_file" "CREATE TABLE IF NOT EXISTS directory (id INTEGER PRIMARY KEY, folder TEXT, session TEXT);"
    fi
}

# Function to manage directories (CRUD operations)
directory_manager() {
    while true; do
        echo "Directory Manager"
        echo "1. Add Directory"
        echo "2. View Directories"
        echo "3. Delete Directory"
        echo "4. Back to Main Menu"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                read -p "Enter folder directory: " folder
                read -p "Enter session directory: " session
                sqlite3 "$db_file" "INSERT INTO directory (folder, session) VALUES ('$folder', '$session');"
                ;;
            2)
                echo "Directories:"
                # Retrieve all directories
                directories=$(sqlite3 "$db_file" "SELECT id, folder, session FROM directory;")
                # Initialize counter
                counter=1
                # Loop through directories
                while IFS='|' read -r id folder session; do
                    echo "$counter - $folder - $session"
                    # Update ID if necessary
                    if [ "$counter" != "$id" ]; then
                        sqlite3 "$db_file" "UPDATE directory SET id=$counter WHERE id=$id;"
                    fi
                    ((counter++))
                done <<< "$directories"
                ;;
            3)
                read -p "Enter directory ID to delete: " id
                # Delete directory
                sqlite3 "$db_file" "DELETE FROM directory WHERE id=$id;"
                echo "Directory deleted."
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice. Please enter a valid option."
                ;;
        esac
    done
}

# Function to execute torrents using xterm
torrents_executor() {
    # Check if .db-torrent directory exists
    if [ ! -d "$db_dir" ]; then
        echo "Error: .db-torrent directory not found. Exiting."
        exit 1
    fi

    # Read directory entries from SQLite database
    # Loop through the entries and execute torrents
    while IFS='|' read -r folder session; do
        # Add echo for clarity
        echo "rtorrent -d '$folder' -s '$session'"
        # Enclose folder and session in quotes to handle spaces
        xterm -e "rtorrent -d '$folder' -s '$session'" &
    done < <(sqlite3 "$db_file" "SELECT folder, session FROM directory;")
}

# Main Menu
while true; do
    echo "Main Menu"
    echo "1. Directory Manager"
    echo "2. Torrents Executor"
    echo "3. Exit"

    read -p "Enter your choice: " main_choice

    case $main_choice in
        1)
            initialize_db
            directory_manager
            ;;
        2)
            torrents_executor
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac
done
