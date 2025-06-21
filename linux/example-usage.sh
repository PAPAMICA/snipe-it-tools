#!/bin/bash

# Script d'exemple pour tester le script de création d'assets SnipeIT
# Ce script montre comment utiliser le script principal avec différents exemples

# Configuration - À modifier selon votre environnement
SNIPEIT_SERVER="https://your-snipeit-server.com"
API_TOKEN="your-api-token-here"

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Script d'exemple pour SnipeIT Asset Creation ===${NC}"
echo

# Vérification des prérequis
echo -e "${YELLOW}Vérification des prérequis...${NC}"
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ curl n'est pas installé"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq n'est pas installé"
    exit 1
fi

if [[ ! -f "./snipeit-centos.sh" ]]; then
    echo "❌ Le script snipeit-centos.sh n'est pas trouvé dans le répertoire courant"
    exit 1
fi

echo "✅ Tous les prérequis sont satisfaits"
echo

# Vérification de la configuration
if [[ "$SNIPEIT_SERVER" == "https://your-snipeit-server.com" ]] || [[ "$API_TOKEN" == "your-api-token-here" ]]; then
    echo -e "${YELLOW}⚠️  ATTENTION: Veuillez modifier les variables SNIPEIT_SERVER et API_TOKEN dans ce script avant de l'exécuter${NC}"
    echo
    echo "Configuration actuelle :"
    echo "  Serveur: $SNIPEIT_SERVER"
    echo "  Token: ${API_TOKEN:0:10}..."
    echo
    echo "Pour modifier, éditez ce fichier et changez les valeurs au début du script."
    exit 1
fi

echo -e "${GREEN}Configuration validée${NC}"
echo "  Serveur: $SNIPEIT_SERVER"
echo "  Token: ${API_TOKEN:0:10}..."
echo

# Fonction pour exécuter un exemple
run_example() {
    local title="$1"
    local description="$2"
    local command="$3"
    
    echo -e "${GREEN}=== $title ===${NC}"
    echo "$description"
    echo
    echo "Commande à exécuter :"
    echo "$command"
    echo
    
    read -p "Voulez-vous exécuter cet exemple ? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Exécution..."
        echo
        eval "$command"
        echo
        echo "Exemple terminé."
    else
        echo "Exemple ignoré."
    fi
    
    echo
    echo "----------------------------------------"
    echo
}

# Exemple 1 : Création d'un PC de bureau simple
run_example \
    "Exemple 1: PC de bureau simple" \
    "Création d'un PC de bureau avec les informations de base" \
    "./snipeit-centos.sh \
        -s \"$SNIPEIT_SERVER\" \
        -t \"$API_TOKEN\" \
        -m \"Dell OptiPlex 7090\" \
        -n \"PC-001\" \
        --hostname \"pc001.company.com\" \
        --ip-address \"192.168.1.100\" \
        --memory 16 \
        --vcpu 8 \
        --os \"Ubuntu 22.04\""

# Exemple 2 : Création d'un laptop avec logiciels
run_example \
    "Exemple 2: Laptop avec logiciels" \
    "Création d'un laptop avec informations détaillées et logiciels" \
    "./snipeit-centos.sh \
        -s \"$SNIPEIT_SERVER\" \
        -t \"$API_TOKEN\" \
        -m \"HP ProBook 450\" \
        -n \"LAPTOP-001\" \
        --hostname \"laptop001.company.com\" \
        --ip-address \"192.168.1.101\" \
        --memory 32 \
        --vcpu 16 \
        --os \"Windows 11\" \
        --disks \"SSD 1TB\" \
        --software \"Office 365, Teams, Zoom, Chrome, Firefox\""

# Exemple 3 : Création d'un serveur avec informations complètes
run_example \
    "Exemple 3: Serveur avec informations complètes" \
    "Création d'un serveur avec toutes les informations disponibles" \
    "./snipeit-centos.sh \
        -s \"$SNIPEIT_SERVER\" \
        -t \"$API_TOKEN\" \
        -m \"Dell PowerEdge R740\" \
        -n \"SRV-PROD-01\" \
        -a \"SRV001\" \
        -c \"Ma Société\" \
        -l \"Datacenter Principal\" \
        -d \"IT Infrastructure\" \
        -u \"Dell Technologies\" \
        -p \"2024-01-15\" \
        -w 36 \
        -o \"PO-2024-001\" \
        -i \"INV-2024-001\" \
        --hostname \"srv-prod-01.company.com\" \
        --ip-address \"10.0.1.100\" \
        --memory 128 \
        --vcpu 32 \
        --os \"Ubuntu Server 22.04 LTS\" \
        --disks \"2x SSD 1TB RAID1, 4x HDD 4TB RAID5\" \
        --software \"Docker, Kubernetes, PostgreSQL, Redis, Nginx\""

# Exemple 4 : Test avec mode verbose
run_example \
    "Exemple 4: Test avec mode verbose" \
    "Création d'un asset avec le mode verbose pour voir tous les détails" \
    "./snipeit-centos.sh \
        -s \"$SNIPEIT_SERVER\" \
        -t \"$API_TOKEN\" \
        -m \"Dell OptiPlex 7090\" \
        -n \"PC-TEST-VERBOSE\" \
        --hostname \"pc-test.company.com\" \
        --ip-address \"192.168.1.200\" \
        --memory 8 \
        --vcpu 4 \
        --os \"Ubuntu 20.04\" \
        -v"

# Exemple 5 : Test d'aide
run_example \
    "Exemple 5: Affichage de l'aide" \
    "Affichage de l'aide du script pour voir toutes les options disponibles" \
    "./snipeit-centos.sh -h"

echo -e "${GREEN}=== Fin des exemples ===${NC}"
echo
echo "Pour plus d'informations, consultez le README.md"
echo "ou exécutez : ./snipeit-centos.sh -h" 