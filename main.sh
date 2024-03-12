# Define the file to store the to-do list
todo_file="todo.txt"

# Function to display the to-do list
view_list() {
    if [ -s "$todo_file" ]; then
        content=$(awk -F ';' '{printf "%-20s %-10s %-30s %s\n", $1, $2, $3, $4}' "$todo_file")
        zenity --text-info --title="To-Do List" --width=800 --height=400 --editable --filename=<(echo "$content")
    else
        zenity --info --title="To-Do List" --text="To-do list is empty." --width=400 --height=200
    fi
}


add_item() {
    category=$(zenity --list --title="Choose Category" --column="Option" \
        --width=500 --height=600 \
        "Health" "Money" "Relax" "Games" "Learning")
    if [ "$category" != "" ]; then
        priority=$(zenity --list --title="Choose Priority" --column="Option" \
            --width=400 --height=300 \
            "High" "Medium" "Low")
        if [ "$priority" != "" ]; then
            new_item=$(zenity --entry --title="Add New Item" --text="Enter the new item:")
            reminder_date=$(zenity --calendar --title="Set Reminder Date" --text="Choose a reminder date:" --date-format="%Y-%m-%d")
            reminder_time=$(zenity --entry --title="Set Reminder Time" --text="Enter the reminder time (optional):" --entry-text="HH:MM")
            reminder_datetime="$reminder_date $reminder_time"
            # Validate input using regular expression
            if [[ ! "$new_item" =~ ^[a-zA-Z]+$ ]]; then
                zenity --error --title="Error" --text="Invalid input. Only alphabetic characters are allowed."
                return
            fi
            
            echo "$category;$priority;$new_item;$reminder_datetime" >> "$todo_file"
            zenity --info --title="To-Do List" --text="Item added to the to-do list with reminder."
        fi
    fi
}

# Function to mark an item as done by entering its name or viewing details
mark_done() {
    item_name=$(zenity --entry --title="Mark Item as Done" --text="Enter the name of the item or view details:")
    if [ "$item_name" != "" ]; then
        item_details=$(grep -i "$item_name" "$todo_file")
        if [ -n "$item_details" ]; then
            sed -i "/$item_name/d" "$todo_file"
            zenity --info --title="To-Do List" --text="Item '$item_name' marked as done."
        else
            zenity --info --title="To-Do List" --text="No item found with the name '$item_name'."
        fi
    fi
}

# Function to remove an item from the to-do list by name
remove_item() {
    item_name=$(zenity --entry --title="Remove Item" --text="Enter the name of the item to remove:")
    if [ "$item_name" != "" ]; then
        sed -i "/$item_name/d" "$todo_file"
        zenity --info --title="To-Do List" --text="Item '$item_name' removed from the to-do list."
    fi
}

# Function to clear the entire to-do list
clear_list() {
    zenity --question --title="Clear To-Do List" --text="Are you sure you want to clear the entire to-do list?"
    if [ $? -eq 0 ]; then
        > "$todo_file" # Clears the file
        zenity --info --title="To-Do List" --text="To-do list cleared."
    fi
}

# Function to check reminders
check_reminders() {
    while true; do
        # Read the todo file line by line
        while IFS= read -r line; do
            reminder_datetime=$(echo "$line" | awk -F ';' '{print $4}')
            task=$(echo "$line" | awk -F ';' '{print $3}')
            # Check if the reminder datetime matches the current datetime
            if [ "$(date '+%Y-%m-%d %H:%M')" = "$reminder_datetime" ]; then
                zenity --info --title="Reminder" --text="Reminder: $task" &
            fi
        done < "$todo_file"
        sleep 60 # Check every minute
    done
}

# Start checking reminders in the background
check_reminders &

# Main loop
while true; do
    choice=$(zenity --list --title="To-Do List" --column="Option" \
        --width=400 --height=300 \
        "Add a new item" "View to-do list" "Mark an item as done" "Remove an item" "Clear the to-do list" "Exit")
    case $choice in
        "Add a new item")
            add_item ;;
        "View to-do list") 
            view_list ;;
        "Mark an item as done")
            mark_done ;;
        "Remove an item")
            remove_item ;;
        "Clear the to-do list")
            clear_list ;;
        "Exit")
            echo "Exiting......."; break ;;
        *) 
            zenity --error --title="Error" --text="Invalid choice. Please try again." ;;
    esac
done
