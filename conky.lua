-- -------------------------------------------------------------------
-- File: conky.lua
-- Type: Lua helper functions for Conky
-- By Arnold
-- Last modified: 2025-01-11
-- -------------------------------------------------------------------

-- Get distribution name
function conky_get_distro()
local handle = io.popen("cat /etc/os-release 2>/dev/null | grep '^NAME=' | cut -d'=' -f2 | tr -d '\"'")
if handle then
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("^%s*(.-)%s*$", "%1")
    if result ~= "" then
        return result
        end
        end

        handle = io.popen("cat /etc/arch-release 2>/dev/null")
        if handle then
            local result = handle:read("*a")
            handle:close()
            result = result:gsub("^%s*(.-)%s*$", "%1")
            if result ~= "" then
                return result
                end
                end

                return "Arch Linux"
                end

                -- Get CPU model cleaned up
                function conky_get_cpu_model()
                local handle = io.popen("cat /proc/cpuinfo | grep 'model name' | head -1 | sed -e 's/model name.*: //' | sed -e 's/(R)//' | sed -e 's/(TM)//' | sed 's/CPU//g' | sed 's/0 @//g'")
                if not handle then
                    return "N/A"
                    end
                    local result = handle:read("*a")
                    handle:close()
                    return result:gsub("^%s*(.-)%s*$", "%1")
                    end

                    -- Get CPU temperature
                    function conky_get_cpu_temp()
                    local handle = io.popen("sensors 2>/dev/null | grep 'Package id 0:' | awk '{print $4}' | tr -d '+'")
                    if not handle then
                        return "N/A"
                        end
                        local result = handle:read("*a")
                        handle:close()
                        result = result:gsub("^%s*(.-)%s*$", "%1")
                        if result == "" then
                            return "N/A"
                            end
                            return result
                            end

                            -- Get CPU temperature color based on value
                            function conky_get_cpu_temp_color()
                            local handle = io.popen("sensors 2>/dev/null | grep 'Package id 0:' | awk '{print $4}' | tr -d '+' | cut -d'.' -f1 | tr -d '°C'")
                            if not handle then
                                return "${color8}"
                                end
                                local result = handle:read("*a")
                                handle:close()
                                result = result:gsub("^%s*(.-)%s*$", "%1")
                                local temp = tonumber(result)
                                if not temp then
                                    return "${color8}"
                                    end

                                    if temp >= 80 then
                                        return "${color4}"  -- Red for high temp
                                        elseif temp >= 65 then
                                            return "${color5}"  -- Orange for warm
                                            else
                                                return "${color8}"  -- Green for normal
                                                end
                                                end

                                                -- Get network total for single interface (rx)
                                                function conky_get_net_rx(iface)
                                                local path = "/sys/class/net/" .. iface .. "/statistics/rx_bytes"
                                                local file = io.open(path, "r")
                                                if not file then
                                                    return "0.00 MB"
                                                    end
                                                    local bytes = file:read("*n")
                                                    file:close()
                                                    if not bytes then
                                                        return "0.00 MB"
                                                        end
                                                        local mb = bytes / 1048576
                                                        return string.format("%.2f MB", mb)
                                                        end

                                                        -- Get network total for single interface (tx)
                                                        function conky_get_net_tx(iface)
                                                        local path = "/sys/class/net/" .. iface .. "/statistics/tx_bytes"
                                                        local file = io.open(path, "r")
                                                        if not file then
                                                            return "0.00 MB"
                                                            end
                                                            local bytes = file:read("*n")
                                                            file:close()
                                                            if not bytes then
                                                                return "0.00 MB"
                                                                end
                                                                local mb = bytes / 1048576
                                                                return string.format("%.2f MB", mb)
                                                                end

                                                                -- Get WiFi total rx (combines wlan0 and wlan1)
                                                                function conky_get_wifi_rx()
                                                                local total = 0
                                                                local interfaces = {"wlan0", "wlan1"}

                                                                for _, iface in ipairs(interfaces) do
                                                                    local path = "/sys/class/net/" .. iface .. "/statistics/rx_bytes"
                                                                    local file = io.open(path, "r")
                                                                    if file then
                                                                        local bytes = file:read("*n")
                                                                        if bytes then
                                                                            total = total + bytes
                                                                            end
                                                                            file:close()
                                                                            end
                                                                            end

                                                                            local mb = total / 1048576
                                                                            return string.format("%.2f MB", mb)
                                                                            end

                                                                            -- Get WiFi total tx (combines wlan0 and wlan1)
                                                                            function conky_get_wifi_tx()
                                                                            local total = 0
                                                                            local interfaces = {"wlan0", "wlan1"}

                                                                            for _, iface in ipairs(interfaces) do
                                                                                local path = "/sys/class/net/" .. iface .. "/statistics/tx_bytes"
                                                                                local file = io.open(path, "r")
                                                                                if file then
                                                                                    local bytes = file:read("*n")
                                                                                    if bytes then
                                                                                        total = total + bytes
                                                                                        end
                                                                                        file:close()
                                                                                        end
                                                                                        end

                                                                                        local mb = total / 1048576
                                                                                        return string.format("%.2f MB", mb)
                                                                                        end

                                                                                        -- Get GPU model
                                                                                        function conky_get_gpu_model()
                                                                                        local handle = io.popen("lspci 2>/dev/null | grep -i 'vga' | cut -d ':' -f3 | sed 's/^ *//'")
                                                                                        if not handle then
                                                                                            return "N/A"
                                                                                            end
                                                                                            local result = handle:read("*a")
                                                                                            handle:close()
                                                                                            return result:gsub("^%s*(.-)%s*$", "%1")
                                                                                            end

                                                                                            -- Get GPU vendor ID
                                                                                            function conky_get_gpu_vendor()
                                                                                            local handle = io.popen("lspci -nn 2>/dev/null | grep -i 'vga' | cut -d '[' -f2 | cut -d ']' -f1")
                                                                                            if not handle then
                                                                                                return "N/A"
                                                                                                end
                                                                                                local result = handle:read("*a")
                                                                                                handle:close()
                                                                                                return result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                end

                                                                                                -- Get screen resolution
                                                                                                function conky_get_resolution()
                                                                                                local handle = io.popen("xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}'")
                                                                                                if not handle then
                                                                                                    return "N/A"
                                                                                                    end
                                                                                                    local result = handle:read("*a")
                                                                                                    handle:close()
                                                                                                    result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                    if result == "" then
                                                                                                        -- Fallback to xrandr
                                                                                                        handle = io.popen("xrandr 2>/dev/null | grep ' connected' | grep -oP '\\d+x\\d+' | head -1")
                                                                                                        if handle then
                                                                                                            result = handle:read("*a")
                                                                                                            handle:close()
                                                                                                            result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                            end
                                                                                                            end
                                                                                                            if result == "" then
                                                                                                                return "N/A"
                                                                                                                end
                                                                                                                return result
                                                                                                                end

                                                                                                                -- Get NVMe temperature
                                                                                                                function conky_get_nvme_temp()
                                                                                                                -- Method 1: Try sysfs (no sudo needed)
                                                                                                                local handle = io.popen("cat /sys/class/nvme/nvme0/device/hwmon/*/temp1_input 2>/dev/null")
                                                                                                                if handle then
                                                                                                                    local result = handle:read("*a")
                                                                                                                    handle:close()
                                                                                                                    result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                    if result ~= "" then
                                                                                                                        local temp = tonumber(result)
                                                                                                                        if temp then
                                                                                                                            return string.format("%.0f", temp / 1000)
                                                                                                                            end
                                                                                                                            end
                                                                                                                            end

                                                                                                                            -- Method 2: Try hwmon directly
                                                                                                                            handle = io.popen("for f in /sys/class/hwmon/hwmon*/name; do if grep -q nvme $f 2>/dev/null; then cat $(dirname $f)/temp1_input 2>/dev/null; break; fi; done")
                                                                                                                            if handle then
                                                                                                                                local result = handle:read("*a")
                                                                                                                                handle:close()
                                                                                                                                result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                                if result ~= "" then
                                                                                                                                    local temp = tonumber(result)
                                                                                                                                    if temp then
                                                                                                                                        return string.format("%.0f", temp / 1000)
                                                                                                                                        end
                                                                                                                                        end
                                                                                                                                        end

                                                                                                                                        -- Method 3: Try sensors
                                                                                                                                        handle = io.popen("sensors 2>/dev/null | grep -i 'nvme\\|Composite' | grep -oP '\\+\\K[0-9.]+' | head -1")
                                                                                                                                        if handle then
                                                                                                                                            local result = handle:read("*a")
                                                                                                                                            handle:close()
                                                                                                                                            result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                                            if result ~= "" then
                                                                                                                                                local temp = tonumber(result)
                                                                                                                                                if temp then
                                                                                                                                                    return string.format("%.0f", temp)
                                                                                                                                                    end
                                                                                                                                                    end
                                                                                                                                                    end

                                                                                                                                                    -- Method 4: Try smartctl
                                                                                                                                                    handle = io.popen("sudo smartctl -A /dev/nvme0n1 2>/dev/null | grep -i temperature | awk '{print $2}' | head -1")
                                                                                                                                                    if handle then
                                                                                                                                                        local result = handle:read("*a")
                                                                                                                                                        handle:close()
                                                                                                                                                        result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                                                        if result ~= "" then
                                                                                                                                                            return result
                                                                                                                                                            end
                                                                                                                                                            end

                                                                                                                                                            return "N/A"
                                                                                                                                                            end

                                                                                                                                                            -- Get GPU usage percentage (Intel integrated GPU)
                                                                                                                                                            function conky_get_gpu_usage()
                                                                                                                                                            -- Try intel_gpu_top first (requires intel-gpu-tools package and sudo permissions)
                                                                                                                                                            local handle = io.popen("sudo timeout 0.1 intel_gpu_top -J -s 100 2>/dev/null | grep -oP '\"busy\":\\s*\\K[0-9.]+' | head -1")
                                                                                                                                                            if handle then
                                                                                                                                                                local result = handle:read("*a")
                                                                                                                                                                handle:close()
                                                                                                                                                                result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                                                                if result ~= "" then
                                                                                                                                                                    local usage = tonumber(result)
                                                                                                                                                                    if usage then
                                                                                                                                                                        return string.format("%.0f", usage)
                                                                                                                                                                        end
                                                                                                                                                                        end
                                                                                                                                                                        end

                                                                                                                                                                        -- Try reading from sysfs (works for some Intel GPUs)
                                                                                                                                                                        local file = io.open("/sys/class/drm/card0/gt_cur_freq_mhz", "r")
                                                                                                                                                                        if file then
                                                                                                                                                                            local cur_freq = file:read("*n")
                                                                                                                                                                            file:close()

                                                                                                                                                                            local max_file = io.open("/sys/class/drm/card0/gt_max_freq_mhz", "r")
                                                                                                                                                                            if max_file then
                                                                                                                                                                                local max_freq = max_file:read("*n")
                                                                                                                                                                                max_file:close()

                                                                                                                                                                                if cur_freq and max_freq and max_freq > 0 then
                                                                                                                                                                                    local usage = (cur_freq / max_freq) * 100
                                                                                                                                                                                    return string.format("%.0f", usage)
                                                                                                                                                                                    end
                                                                                                                                                                                    end
                                                                                                                                                                                    end

                                                                                                                                                                                    -- Try radeontop for AMD GPUs
                                                                                                                                                                                    handle = io.popen("timeout 0.1 radeontop -d - -l 1 2>/dev/null | grep -oP 'gpu\\s+\\K[0-9.]+' | head -1")
                                                                                                                                                                                    if handle then
                                                                                                                                                                                        local result = handle:read("*a")
                                                                                                                                                                                        handle:close()
                                                                                                                                                                                        result = result:gsub("^%s*(.-)%s*$", "%1")
                                                                                                                                                                                        if result ~= "" then
                                                                                                                                                                                            return result
                                                                                                                                                                                            end
                                                                                                                                                                                            end

                                                                                                                                                                                            return "N/A"
                                                                                                                                                                                            end
