#!/bin/bash
# CYRAX SANDBOX DETECTOR - Detecta ambientes virtualizados/sandbox
echo "=== CYRAX SANDBOX DETECTOR ==="

TEMP_DIR="/tmp/cyrax_sandbox_$(date +%s)"
mkdir -p "$TEMP_DIR"

# Verificar se estamos em VM
check_virtualization() {
    echo "🔍 Verificando virtualização..."
    
    # Verificar DMI
    if [ -r /sys/class/dmi/id/product_name ]; then
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        if echo "$product" | grep -qi "virtualbox\|vmware\|qemu\|kvm\|xen"; then
            echo "⚠️  VM DETECTADA: $product"
            echo "VM:$product" >> "$TEMP_DIR/vm_detected.txt"
        fi
    fi
    
    # Verificar CPU
    if grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
        echo "⚠️  HYPERVISOR DETECTADO"
        echo "HYPERVISOR" >> "$TEMP_DIR/vm_detected.txt"
    fi
    
    # Verificar MAC addresses suspeitos
    local vm_macs=("08:00:27" "00:0C:29" "00:1C:14" "00:50:56")
    for mac_prefix in "${vm_macs[@]}"; do
        if ip link show 2>/dev/null | grep -qi "$mac_prefix"; then
            echo "⚠️  MAC VIRTUALIZADO: $mac_prefix"
            echo "MAC:$mac_prefix" >> "$TEMP_DIR/vm_detected.txt"
        fi
    done
}

# Verificar recursos limitados (sandbox)
check_resources() {
    echo "🔍 Verificando recursos do sistema..."
    
    # RAM muito baixa
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$ram_mb" -lt 1024 ]; then
        echo "⚠️  RAM SUSPEITA: ${ram_mb}MB (muito baixa)"
        echo "LOW_RAM:$ram_mb" >> "$TEMP_DIR/sandbox_detected.txt"
    fi
    
    # CPU cores muito baixos
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        echo "⚠️  CPU SUSPEITA: $cpu_cores cores (muito baixo)"
        echo "LOW_CPU:$cpu_cores" >> "$TEMP_DIR/sandbox_detected.txt"
    fi
    
    # Disco muito pequeno
    local disk_gb=$(df / | awk 'NR==2{print int($2/1024/1024)}')
    if [ "$disk_gb" -lt 10 ]; then
        echo "⚠️  DISCO SUSPEITO: ${disk_gb}GB (muito pequeno)"
        echo "LOW_DISK:$disk_gb" >> "$TEMP_DIR/sandbox_detected.txt"
    fi
}

# Verificar processos de análise
check_analysis_processes() {
    echo "🔍 Verificando processos de análise..."
    
    local analysis_procs=(
        "wireshark" "tcpdump" "strace" "ltrace" "gdb"
        "ollydbg" "ida" "ghidra" "radare2" "x64dbg"
        "procmon" "regmon" "filemon" "apimonitor"
        "sandboxie" "cuckoo" "anubis" "joebox"
    )
    
    for proc in "${analysis_procs[@]}"; do
        if pgrep -i "$proc" >/dev/null 2>&1; then
            echo "⚠️  PROCESSO DE ANÁLISE: $proc"
            echo "ANALYSIS:$proc" >> "$TEMP_DIR/sandbox_detected.txt"
        fi
    done
}

# Verificar tempo de boot (sandbox geralmente tem boot recente)
check_uptime() {
    local uptime_hours=$(awk '{print int($1/3600)}' /proc/uptime)
    if [ "$uptime_hours" -lt 1 ]; then
        echo "⚠️  UPTIME SUSPEITO: ${uptime_hours}h (muito recente)"
        echo "LOW_UPTIME:$uptime_hours" >> "$TEMP_DIR/sandbox_detected.txt"
    fi
}

# Executar verificações
check_virtualization
check_resources
check_analysis_processes
check_uptime

# Resumo
echo ""
echo "📊 RESUMO DA ANÁLISE:"
if [ -f "$TEMP_DIR/vm_detected.txt" ] || [ -f "$TEMP_DIR/sandbox_detected.txt" ]; then
    echo "⚠️  AMBIENTE SUSPEITO DETECTADO!"
    echo "🛡️  RECOMENDAÇÃO: Usar máxima evasão"
else
    echo "✅ Ambiente parece seguro"
fi

echo "Detalhes em: $TEMP_DIR"