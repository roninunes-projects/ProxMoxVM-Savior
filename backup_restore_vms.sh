#!/bin/bash

# Variáveis de configuração
DESTINO="/mnt/pve/BACKUP-SRVAAT"
DATA=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$DESTINO/backup-vms-proxmox/$DATA"
DISCOS_DIR="$BACKUP_DIR/discos"
CONFIGS_DIR="$BACKUP_DIR/config-discos"
LOG_FILE="$BACKUP_DIR/backup.log"
REDE=""
NOVO_SERVIDOR=""
USUARIO=""
CAMINHO_REMOTO=""

# Função para criar diretórios se não existirem
criar_diretorios() {
    mkdir -p "$DISCOS_DIR"
    mkdir -p "$CONFIGS_DIR"
}

# Função para logar mensagens
log() {
    echo "$(date +%Y-%m-%d_%H-%M-%S) - $1" | tee -a "$LOG_FILE"
}

# Função para listar VMs iniciadas
listar_vms_iniciadas() {
    qm list | awk '$3 == "running" {print $1, $2}'
}

# Função para parar VMs
parar_vm() {
    local vmid=$1
    log "Parando VM $vmid"
    qm stop $vmid
    if [[ $? -ne 0 ]]; então
        log "Erro ao parar VM $vmid"
        return 1
    fi
}

# Função para iniciar VMs
iniciar_vm() {
    local vmid=$1
    log "Iniciando VM $vmid"
    qm start $vmid
    if [[ $? -ne 0 ]]; então
        log "Erro ao iniciar VM $vmid"
        return 1
    fi
}

# Função para copiar discos e configurações
copiar_vm() {
    local vmid=$1
    log "Copiando discos e configuração da VM $vmid"
    dd if="/dev/LVM-Thin_nvme0n1/vm-${vmid}-disk-0" of="$DISCOS_DIR/vm-${vmid}-disk-0.img" bs=1M 2>>"$LOG_FILE"
    if [[ $? -ne 0 ]]; então
        log "Erro ao copiar disco da VM $vmid"
        return 1
    fi
    cp "/etc/pve/qemu-server/${vmid}.conf" "$CONFIGS_DIR/vm-${vmid}.conf" 2>>"$LOG_FILE"
    if [[ $? -ne 0 ]]; então
        log "Erro ao copiar configuração da VM $vmid"
        return 1
    fi
    log "Cópia da VM $vmid concluída com sucesso"
}

# Função para copiar discos e configurações com parada da VM
copiar_vm_com_parada() {
    local vmid=$1
    local status=$2
    if [[ "$status" == "running" ]]; então
        parar_vm $vmid
    fi
    copiar_vm $vmid
    if [[ "$status" == "running" ]]; então
        iniciar_vm $vmid
    fi
}

# Função para restaurar discos e configurações
restaurar_vm() {
    local vmid=$1
    log "Restaurando discos e configuração da VM $vmid"
    dd if="$DISCOS_DIR/vm-${vmid}-disk-0.img" of="/dev/LVM-Thin_nvme0n1/vm-${vmid}-disk-0" bs=1M 2>>"$LOG_FILE"
    if [[ $? -ne 0 ]]; então
        log "Erro ao restaurar disco da VM $vmid"
        return 1
    fi
    cp "$CONFIGS_DIR/vm-${vmid}.conf" "/etc/pve/qemu-server/${vmid}.conf" 2>>"$LOG_FILE"
    if [[ $? -ne 0 ]]; então
        log "Erro ao restaurar configuração da VM $vmid"
        return 1
    fi
    log "Restauração da VM $vmid concluída com sucesso"
    iniciar_vm $vmid  # Inicia a VM após a restauração
}

# Função para transferir backups para o novo servidor
transferir_backups() {
    log "Transferindo backups para o novo servidor"
    scp -r "$BACKUP_DIR" "$USUARIO@$NOVO_SERVIDOR:$CAMINHO_REMOTO"
    if [[ $? -ne 0 ]]; então
        log "Erro ao transferir backups para o novo servidor"
        return 1
    fi
}

# Função principal
main() {
    criar_diretorios

    echo "Deseja fazer backup ou restaurar? (backup/restaurar)"
    read operacao

    if [[ "$operacao" == "backup" ]]; então
        echo "Deseja parar as VMs durante o backup para garantir a consistência dos dados? (s/n)"
        read parar_vm_durante_backup
        echo "Deseja fazer backup localmente, em uma unidade de rede ou transferir para um novo servidor? (local/rede/transferir)"
        read destino_backup
        if [[ "$destino_backup" == "rede" ]]; então
            echo "Digite o caminho da unidade de rede (ex: //server/share):"
            read REDE
            BACKUP_DIR="$REDE/backup-vms-proxmox/$DATA"
            DISCOS_DIR="$BACKUP_DIR/discos"
            CONFIGS_DIR="$BACKUP_DIR/config-discos"
            criar_diretorios
        elif [[ "$destino_backup" == "transferir" ]]; então
            echo "Digite o endereço do novo servidor:"
            read NOVO_SERVIDOR
            echo "Digite o usuário para o novo servidor:"
            read USUARIO
            echo "Digite o caminho remoto no novo servidor:"
            read CAMINHO_REMOTO
        fi
        for vm in $(qm list | awk 'NR>1 {print $1 " " $2 " " $3}'); do
            vmid=$(echo $vm | awk '{print $1}')
            nome=$(echo $vm | awk '{print $2}')
            status=$(echo $vm | awk '{print $3}')
            if [[ "$parar_vm_durante_backup" == "s" ]]; então
                copiar_vm_com_parada $vmid $status
            else
                copiar_vm $vmid
            fi
        done
        if [[ "$destino_backup" == "transferir" ]]; então
            transferir_backups
        fi
    elif [[ "$operacao" == "restaurar" ]]; então
        echo "Deseja restaurar todas as VMs ou apenas algumas? (todas/algumas)"
        read restaurar_opcao
        if [[ "$restaurar_opcao" == "todas" ]]; então
            for vmid in $(ls $CONFIGS_DIR | awk -F '-' '{print $2}'); do
                restaurar_vm $vmid
            done
        elif [[ "$restaurar_opcao" == "algumas" ]]; então
            echo "Digite os IDs das VMs para restaurar, separados por vírgulas (ex: 100, 101, 102):"
            read vm_ids
            IFS=',' read -r -a vmid_array <<< "$vm_ids"
            for vmid in "${vmid_array[@]}"; do
                vmid=$(echo $vmid | xargs)  # Remove espaços em branco ao redor
                restaurar_vm $vmid
            done
        else
            echo "Opção inválida. Por favor, escolha entre 'todas' ou 'algumas'."
            exit 1
        fi
    else
        echo "Operação inválida. Por favor, escolha entre 'backup' ou 'restaurar'."
        exit 1
    fi

    log "Operação $operacao concluída."
}

# Executar função principal
main
