#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
        echo -e "${CYAN}Directory Manager${NC}"
        echo -e "${YELLOW}1.${NC} Create Directory"
        echo -e "${YELLOW}2.${NC} Add Directory"
        echo -e "${YELLOW}3.${NC} View Directories"
        echo -e "${YELLOW}4.${NC} Delete Directory"
        echo -e "${YELLOW}5.${NC} Back to Main Menu"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                create_directory
                ;;
            2)
                add_directory
                ;;
            3)
                view_directories
                ;;
            4)
                delete_directory
                ;;
            5)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter a valid option.${NC}"
                ;;
        esac
    done
}

# Function to validate if a directory exists
validate_directory() {
    local directory="$1"
    if [ ! -d "$directory" ]; then
        echo -e "${RED}Directory $directory does not exist.${NC}"
        return 1
    fi
}

create_directory() {
    while true; do
        read -p "Enter parent folder directory (or 0 to cancel): " parent_folder
        if [ "$parent_folder" -eq 0 ]; then
            break
        fi
        
        read -p "Enter name for the download directory: " download_name
        
        if validate_directory "$parent_folder"; then
            # Generate the unique identifier
            UUID_TEM=$(uuidgen -s -r)
            unique_id=${UUID_TEM:0:8}
        
            # Create the directory structure
            path="${parent_folder}/${download_name}"
            full_path="${parent_folder}/${download_name}/.${unique_id}"
            mkdir "$path"
            mkdir "$full_path"
        
            # Insert the directory into the database
            sqlite3 "$db_file" "INSERT INTO directory (folder, session) VALUES ('$path', '$full_path');"
            echo -e "${GREEN}Directory created: $full_path${NC}"
            break
        fi
    done
}

add_directory() {
    while true; do
        read -p "Enter folder directory (or 0 to cancel): " folder
        if [ "$folder" -eq 0 ]; then
            break
        fi
        
        read -p "Enter session directory: " session

        if [ "$session" -eq 0 ]; then
            break
        fi

        if validate_directory "$folder" && validate_directory "$session"; then
            sqlite3 "$db_file" "INSERT INTO directory (folder, session) VALUES ('$folder', '$session');"
            echo -e "${GREEN}Directory added: $folder${NC}"
            break
        fi
    done
}

# Function to count the number of directories
count_directories() {
    sqlite3 "$db_file" "SELECT COUNT(*) FROM directory;"
}

view_directories() {
    # Count the number of directories
    num_directories=$(count_directories)

    if [ "$num_directories" -eq 0 ]; then
        echo -e "${YELLOW}You have no directories.${NC}"
    else
        echo -e "${CYAN}Directories:${NC}"
        # Retrieve all directories
        directories=$(sqlite3 "$db_file" "SELECT id, folder, session FROM directory;")
        # Initialize counter
        counter=1
        # Loop through directories
        while IFS='|' read -r id folder session; do
            echo -e "${YELLOW}$counter - $folder${NC}\n    $session"
            # Update ID if necessary
            if [ "$counter" != "$id" ]; then
                sqlite3 "$db_file" "UPDATE directory SET id=$counter WHERE id=$id;"
            fi
            ((counter++))
        done <<< "$directories"
    fi
}

delete_directory() {
    # Count the number of directories
    num_directories=$(count_directories)

    if [ "$num_directories" -eq 0 ]; then
        echo -e "${YELLOW}You have no directories to delete.${NC}"
        return
    fi

    view_directories
    
    read -p "Enter directory ID to delete (or 0 to cancel): " id
    if [ "$id" -eq 0 ]; then
        return
    fi

    # Check if the entered ID is valid
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid directory ID. Please enter a valid ID.${NC}"
        return
    fi

    # Check if the entered ID exists in the database
    id_exists=$(sqlite3 "$db_file" "SELECT COUNT(*) FROM directory WHERE id=$id;")
    if [ "$id_exists" -eq 0 ]; then
        echo -e "${RED}Directory ID $id does not exist.${NC}"
        return
    fi

    # Fetch directory and session from the database
    directory=$(sqlite3 "$db_file" "SELECT folder FROM directory WHERE id=$id;")
    session=$(sqlite3 "$db_file" "SELECT session FROM directory WHERE id=$id;")

    # Validate if directory and session exist
    if validate_directory "$directory" && validate_directory "$session"; then
        # Delete session directory
        rm -rf "$session"
        # Delete download directory
        rm -rf "$directory"

        # Delete directory from the database
        sqlite3 "$db_file" "DELETE FROM directory WHERE id=$id;"
        echo -e "${GREEN}Directory deleted.${NC}"
    else
        echo -e "${RED}Invalid directory ID or associated directories not found.${NC}"
    fi
}

manual_execution() {
    while true; do
        echo -e "${CYAN}Manual Execution${NC}"
        view_directories
        read -p "Enter the directory ID to execute (or 0 to cancel): " id
        if [ "$id" -eq 0 ]; then
            break
        fi
        
        if [[ "$id" =~ ^[0-9]+$ ]]; then
            # Fetch directory and session from the database
            directory=$(sqlite3 "$db_file" "SELECT folder FROM directory WHERE id=$id;")
            session=$(sqlite3 "$db_file" "SELECT session FROM directory WHERE id=$id;")

            # Validate if directory and session exist
            if validate_directory "$directory" && validate_directory "$session"; then
                # Execute torrent using xterm
                xterm -e "rtorrent -d '$directory' -s '$session'" &
                echo -e "${GREEN}Torrent started for directory ID $id.${NC}"
                break
            else
                echo -e "${RED}Invalid directory ID or associated directories not found.${NC}"
            fi
        else
            echo -e "${RED}Invalid input. Please enter a valid directory ID.${NC}"
        fi
    done
}

# Function to execute torrents using xterm
torrents_executor() {
    # Check if .db-torrent directory exists
    if [ ! -d "$db_dir" ]; then
        echo -e "${RED}Error: .db-torrent directory not found. Exiting.${NC}"
        exit 1
    fi

    # Read directory entries from SQLite database
    # Loop through the entries and execute torrents
    while IFS='|' read -r folder session; do
        # Add echo for clarity
        echo "rtorrent -d '$folder' -s '$session'"
        # Enclose folder and session in quotes to handle spaces
        xterm -e "rtorrent -d '$folder' -s '$session'" &
        sleep 2
    done < <(sqlite3 "$db_file" "SELECT folder, session FROM directory;")
}

# Main Menu
while true; do
    echo -e "${CYAN}Main Menu${NC}"
    echo -e "${YELLOW}1.${NC} Directory Manager"
    echo -e "${YELLOW}2.${NC} Torrent Executor"
    echo -e "${YELLOW}3.${NC} Manual Execution"
    echo -e "${YELLOW}4.${NC} Exit"

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
            manual_execution
            ;;
        4)
            echo -e "${CYAN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a valid option.${NC}"
            ;;
    esac
done
