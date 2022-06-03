-- Creator -poko
-- Date - 2/6/2022

--GLOBAL INIT
GAME_LIBS = {}




function ReadInt32(addr)
    local from = {{address = addr, flags=4}};
    from = gg.getValues(from);
    return from[1].value;
end

function Num2HexStr(num, uppercase)
    if(not uppercase or uppercase == 0) then
        return (string.format("%x",num)); end
    return (string.format("%X",num));
end

function alreadyHave(compare_t , str)
    for index, element in ipairs(compare_t) do
        if(element ==  str) then
            return true;
        end
    end
    return false;
end

--probably the .bss or .data section in most case
function getLastSection(lib_name)
    local temp_t  = gg.getRangesList(("/data/*" .. lib_name));
    return temp_t[#temp_t]['end']-1;
end

--set GAME_LIBS and return table of strings for UI
--in a sync order to GAME_LIBS
function getSortedGameLibs()
    local return_t = {}
    local lib_maps = gg.getRangesList(("/data/*" .. gg.getTargetInfo().packageName .. "*lib*.so"));       
    for index, element in ipairs(lib_maps) do
        if(element.state == 'Xa' or element.state == 'Cd') then
            org_name = element.internalName:match("/.*/(lib.*%.so)");
            if( not alreadyHave(return_t, org_name) ) then
                element.lastSec = getLastSection(org_name);
                element.org_name = org_name;
                table.insert(GAME_LIBS, element);
                table.insert(return_t, org_name);
            end
            
        end
    end --forloop end
    return return_t;
end

--Dump Elf file (libs)
function dumpELF(data)
    --checking elf header just in case
    if( ReadInt32(data.start) ~= 1179403647) then
        print("Something is wrong !")
        os.exit();
    end
    gg.dumpMemory(data.start, data.lastSec, '/sdcard/dump')
    local old_name = gg.getTargetInfo().packageName .. "-" .. Num2HexStr(data.start) .. "-" .. Num2HexStr(data.lastSec+1) .. ".bin";     
    local new_name = "[" .. Num2HexStr(data.start,1) .. "-" .. Num2HexStr(data.lastSec+1,1) .. "]_" .. data.org_name;
    local save_path = "/sdcard/dump/";
    os.rename((save_path .. old_name), (save_path .. new_name));
    
    gg.alert("Saved Loaction :" .. save_path .. new_name);
    print("Thanks For using the script !");
    os.exit();
end

function entrypoint()
    --show list of libs as menu
    libs_t = getSortedGameLibs();
    if(#libs_t ==0) then
        print("No libs found in this target!");
        os.exit()
    end
    point = gg.choice(libs_t , nil, 'Select Lib to Dump:')
    if not point then print("Thanks! have goood day!") os.exit() end;
    dumpELF(GAME_LIBS[point]);
end


entrypoint();