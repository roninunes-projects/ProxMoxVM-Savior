# ProxMoxVM-Savior
Script para backup e restauração de VMs no Proxmox VE com suporte a unidades de rede e migração de servidor.

## Funcionalidades

- Backup e restauração de VMs no Proxmox VE.
- Opção de parar VMs durante o backup para garantir a consistência dos dados.
- Backup local, em unidade de rede ou transferência para um novo servidor.
- Restauração automática de VMs com inicialização após a restauração.
- Log de operações e tratamento de erros.

## Estrutura do Script

### Variáveis de Configuração

- `DESTINO`: Diretório base para armazenamento dos backups.
- `DATA`: Data e hora atual para criar um diretório único para cada backup.
- `BACKUP_DIR`, `DISCOS_DIR`, `CONFIGS_DIR`: Diretórios para armazenar os backups dos discos e configurações das VMs.
- `LOG_FILE`: Arquivo de log para registrar as operações.
- `REDE`, `NOVO_SERVIDOR`, `USUARIO`, `CAMINHO_REMOTO`: Variáveis para armazenar detalhes da unidade de rede ou do novo servidor.

### Funções

1. **`criar_diretorios`**: Cria os diretórios necessários para armazenar os backups.
2. **`log`**: Registra mensagens de log com data e hora atuais.
3. **`listar_vms_iniciadas`**: Lista as VMs que estão em execução.
4. **`parar_vm`**: Para uma VM específica.
5. **`iniciar_vm`**: Inicia uma VM específica.
6. **`copiar_vm`**: Copia os discos e configurações de uma VM.
7. **`copiar_vm_com_parada`**: Copia discos e configurações de uma VM, parando-a temporariamente se necessário.
8. **`restaurar_vm`**: Restaura os discos e configurações de uma VM e a inicia.
9. **`transferir_backups`**: Transfere os backups para um novo servidor usando `scp`.
10. **`main`**: Função principal que coordena o backup e restauração das VMs.

## Como Usar

1. **Salvar o Script**: Salve o script em um arquivo, por exemplo, `backup_restore_vms.sh`.

2. **Tornar o Script Executável**:
   ```bash
   chmod +x backup_restore_vms.sh
## Como Usar

1. **Salvar o Script**: Salve o script em um arquivo, por exemplo, `backup_restore_vms.sh`.

2. **Tornar o Script Executável**:
   ```bash
   chmod +x backup_restore_vms.sh
3. **Executar o Script**:
   ```bash
   ./backup_restore_vms.sh
### Fluxo de Operação

1. **Escolher Operação:
O script pergunta ao usuário se deseja fazer backup ou restaurar.

2. **Backup:

Pergunta ao usuário se deve parar as VMs durante o backup para garantir a consistência dos dados.
Pergunta ao usuário se deseja fazer backup localmente, em uma unidade de rede ou transferir para um novo servidor.
Realiza o backup das VMs conforme a escolha do usuário.
Se a opção de transferência for escolhida, transfere os backups para o novo servidor.
1. **Restauração:

Pergunta ao usuário se deseja restaurar todas as VMs ou apenas algumas específicas.
Restaura os discos e arquivos de configuração das VMs a partir dos backups.
Inicia automaticamente as VMs após a restauração.
### Exemplo de Uso
Backup**:
   bash
   ./backup_restore_vms.sh
   Deseja fazer backup ou restaurar? (backup/restaurar)
   backup
   Deseja parar as VMs durante o backup para garantir a consistência dos dados? (s/n)
   s
   Deseja fazer backup localmente, em uma unidade de rede ou transferir para um novo servidor? (local/rede/transferir)
   local

### Restauração
bash


Deseja fazer backup ou restaurar? (backup/restaurar)
restaurar
Deseja restaurar todas as VMs ou apenas algumas? (todas/algumas)
algumas
Digite os IDs das VMs para restaurar, separados por vírgulas (ex: 100, 101, 102):
100, 101

### Considerações Finais
Compatibilidade de Configurações: Verifique se as configurações de rede e armazenamento no novo servidor são compatíveis com as configurações no antigo servidor.
Espaço em Disco: Assegure-se de que o novo servidor tenha espaço em disco suficiente para armazenar todas as VMs restauradas.
Testar as VMs: Após restaurar as VMs no novo servidor, teste-as para garantir que estejam funcionando corretamente.
Backup Regular: Configure um plano de backup regular no novo servidor para garantir a segurança dos dados em caso de falhas futuras.
