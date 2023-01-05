#!/usr/bin/bash
clear
readarray -t routeArray < ./Assets/Routes.txt
readarray -t inventoryArray < ./Assets/Inventory.txt


function DrawAsset () {
    if [[ $1 == "-n" ]]; then
        return
    fi

    clear
    cat "$1"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
}

function PerformRoute(){
    # Get route data
    local startIndex="$1-1" 

    local previous_route_line="${routeArray[$startIndex+1]}"
    previous_route_line=${previous_route_line:21}

    local route_prompt="${routeArray[$startIndex+2]}"
    route_prompt=${route_prompt:14}
    
    local route_asset="${routeArray[$startIndex+3]}"
    route_asset=${route_asset:13}

    local visit_counter="${routeArray[$startIndex+4]}"
    visit_counter=${visit_counter:15}

    local lock_status="${routeArray[$startIndex+5]}"
    lock_status=${lock_status:13}

    local stat_check="${routeArray[$startIndex+6]}"
    stat_check=${stat_check:12}

    local choice_count="${routeArray[$startIndex+7]}"
    choice_count=${choice_count:8}
    
    local InventoryBool;
    InventoryBool=$((1))
    # Check stat 
    case "${stat_check}" in
        "GUARD_ADD")
            echo "Guard" >> Inventory
        ;;
        "GUARD_CHECK")
            InventoryBool=$((0))
            for item in "${inventoryArray[@]}"; do
                if [[ "Guard" == "$item" ]]; then
                    InventoryBool=$((1))
                    break
                fi
            done
        ;;
        "GUARD_TRUST_ADD")
            echo "Guard's trust" >> ./Assets/Inventory.txt
            readarray -t inventoryArray < ./Assets/Inventory.txt
        ;;
        "DEAD_GUARD_ADD")
            echo "Guard's death" >> ./Assets/Inventory.txt
            readarray -t inventoryArray < ./Assets/Inventory.txt
        ;;
        "KEY_ADD")
            echo "Key" >> ./Assets/Inventory.txt
            readarray -t inventoryArray < ./Assets/Inventory.txt
        ;;
        "DELETE_SAVE")
            sed -i '$ d' ./Assets/Routes.txt
            echo "" > ./Assets/Inventory.txt
            echo "" >> ./Assets/Routes.txt
        ;;
        "KEY_CHECK")
            InventoryBool=$((0))
            for item in "${inventoryArray[@]}"; do
                if [[ "Key" == "$item" ]]; then
                    InventoryBool=$((1))
                    break
                fi
            done
        ;;
        *)
            true
        ;;
    esac


    if (( InventoryBool == 0)); then
        error="You sadly didn't pass the check, perhaps door is locked or needed person is not with you.\n"
        sleep 1s
        PerformRoute "$previous_route_line"
    fi


    # Check choice Validity
    userInputBool=$((0))
    validity=$((1))
    while ((userInputBool == 0)); do
        # Draw current scene
        DrawAsset "$route_asset"
        if ((validity == 0)); then
            error="Please enter something valid\n"
        fi
        

        # Read input and lowercase it
        echo -en "$error$route_prompt: "
        read -r userInput
        userInput="${userInput,,}"
        error=""

        if [[ "$userInput" =~ ^(save file|save)$ ]]; then
            echo "Saving progress..."
            startIndex=$((startIndex+1))
            sed -i '$ d' ./Assets/Routes.txt
            echo "$startIndex" >> ./Assets/Routes.txt
            echo "Saved successfully"
            continue

        elif [[ "$userInput" =~ ^(load file|load)$ ]]; then
            echo "Loading last save..."
            sleep 1s
            save=$(tail -1 ./Assets/Routes.txt)
            clear
            PerformRoute "$save"
            continue
        fi

        for((i=0;i<choice_count;i++)); do
            if ((userInputBool == 1)); then
                break
            fi
            
            # Take the single choice from the route data
            index=$((startIndex+i+8))
            choice="${routeArray[$index]}"

            # Split the transitions into seperate indeces
            IFS=';'
            read -ra seperatedChoice <<< "$choice"

            # Split the correct answers from each other
            IFS='/'
            read -ra seperatedCorrectChoice <<< "${seperatedChoice[0]}"
            
            for item in "${seperatedCorrectChoice[@]}"; do
                if [[ "$userInput" == "$item" ]]; then
                    selectedChoice=$index
                    userInputBool=$((1))
                    break
                elif [[ "$item" == "ELSE" ]]; then
                    selectedChoice=$index
                    userInputBool=$((1))
                    break
                fi

            done

        done
        
        validity=$((0))

    done

    # Get the selected choice data
    IFS=';'
    choice="${routeArray[$selectedChoice]}"
    read -ra seperatedChoice <<< "$choice"
    seperatedChoice=("${seperatedChoice[@]:1}") 

    # Iterate over results
    for result in "${seperatedChoice[@]}"; do
        if [ "${result:0:1}" == "\`" ]; then
            # Echo the prompt
            result=${result:1}
            result=${result::-1}
            echo -e "$result"
            n=${#result}
            for((i=0;i<n;i++)); do
                i=$((i*10))
                sleep 1s
            done

        elif [ "${result:0:1}" == "-" ]; then
            # Deal with the flag
            result=${result:1}
            if [ "$result" == "e" ]; then
                exit 1
            else
                PerformRoute "$result"
            fi
            
        fi
        
    done
    
    
}



echo $'The year is 2050, a pandemic has devoured the world. \nA virus has appeared that haunts a human\'s brain and controls it. \nYou and your daughter try to survive in this world of zombies, but she gets kidnapped one day. \nYou have followed the kidnappers until this cave and you plan to storm in and take your daughter back....\n\n    Tip: You can save and load progress at anytime by typing "save" or "load" respectively\n'
PerformRoute 1
