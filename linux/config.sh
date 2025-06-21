#!/bin/bash

# Configuration pour le script SnipeIT
# Ce fichier contient les paramètres par défaut pour votre environnement SnipeIT

# Configuration du serveur SnipeIT
export SNIPEIT_SERVER="https://your-snipeit-server.com"
export API_TOKEN="your-api-token-here"

# Configuration par défaut pour les assets
export DEFAULT_COMPANY=""
export DEFAULT_LOCATION=""
export DEFAULT_DEPARTMENT=""
export DEFAULT_SUPPLIER=""

# Modèles d'assets courants (pour faciliter l'utilisation)
export COMMON_MODELS=(
    "Dell OptiPlex 7090"
    "Dell OptiPlex 7080"
    "HP ProBook 450"
    "HP EliteBook 840"
    "Dell PowerEdge R740"
    "Dell PowerEdge R750"
    "HP ProLiant DL380"
    "Lenovo ThinkPad T14"
    "Lenovo ThinkPad X1 Carbon"
)

# Emplacements courants
export COMMON_LOCATIONS=(
    "Bureau Principal"
    "Datacenter Principal"
    "Site Secondaire"
    "Bureau Régional"
    "Salle Serveurs"
)

# Départements courants
export COMMON_DEPARTMENTS=(
    "IT Infrastructure"
    "Développement"
    "Support Technique"
    "Administration"
    "Marketing"
    "Ventes"
)

# Fournisseurs courants
export COMMON_SUPPLIERS=(
    "Dell Technologies"
    "HP Inc."
    "Lenovo"
    "Apple"
    "Cisco"
)

# Systèmes d'exploitation courants
export COMMON_OS=(
    "Ubuntu 22.04 LTS"
    "Ubuntu 20.04 LTS"
    "Windows 11 Pro"
    "Windows 10 Pro"
    "macOS Ventura"
    "macOS Sonoma"
    "CentOS 7"
    "RHEL 8"
    "RHEL 9"
)

# Logiciels courants
export COMMON_SOFTWARE=(
    "Office 365"
    "Google Chrome"
    "Mozilla Firefox"
    "Microsoft Teams"
    "Zoom"
    "Slack"
    "Visual Studio Code"
    "Docker"
    "Git"
)

# Fonction pour afficher les options disponibles
show_common_options() {
    echo "=== Options courantes disponibles ==="
    echo
    
    echo "📋 Modèles courants :"
    for model in "${COMMON_MODELS[@]}"; do
        echo "  - $model"
    done
    echo
    
    echo "📍 Emplacements courants :"
    for location in "${COMMON_LOCATIONS[@]}"; do
        echo "  - $location"
    done
    echo
    
    echo "🏢 Départements courants :"
    for dept in "${COMMON_DEPARTMENTS[@]}"; do
        echo "  - $dept"
    done
    echo
    
    echo "🏪 Fournisseurs courants :"
    for supplier in "${COMMON_SUPPLIERS[@]}"; do
        echo "  - $supplier"
    done
    echo
    
    echo "💻 Systèmes d'exploitation courants :"
    for os in "${COMMON_OS[@]}"; do
        echo "  - $os"
    done
    echo
    
    echo "🛠️ Logiciels courants :"
    for software in "${COMMON_SOFTWARE[@]}"; do
        echo "  - $software"
    done
    echo
}

# Fonction pour vérifier la configuration
check_config() {
    local errors=()
    
    if [[ "$SNIPEIT_SERVER" == "https://your-snipeit-server.com" ]]; then
        errors+=("SNIPEIT_SERVER n'est pas configuré")
    fi
    
    if [[ "$API_TOKEN" == "your-api-token-here" ]]; then
        errors+=("API_TOKEN n'est pas configuré")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "❌ Erreurs de configuration détectées :"
        for error in "${errors[@]}"; do
            echo "  - $error"
        done
        echo
        echo "Veuillez modifier ce fichier config.sh avec vos vraies valeurs."
        return 1
    fi
    
    echo "✅ Configuration valide"
    return 0
}

# Fonction pour créer un asset avec la configuration par défaut
create_asset_with_defaults() {
    local model="$1"
    local name="$2"
    local hostname="$3"
    local ip_address="$4"
    local memory="$5"
    local vcpu="$6"
    local os="$7"
    local disks="$8"
    local software="$9"
    
    # Utilisation des valeurs par défaut si non spécifiées
    [[ -z "$model" ]] && model="${COMMON_MODELS[0]}"
    [[ -z "$os" ]] && os="${COMMON_OS[0]}"
    [[ -z "$memory" ]] && memory="16"
    [[ -z "$vcpu" ]] && vcpu="8"
    
    # Construction de la commande
    local cmd="./snipeit-centos.sh"
    cmd="$cmd -s \"$SNIPEIT_SERVER\""
    cmd="$cmd -t \"$API_TOKEN\""
    cmd="$cmd -m \"$model\""
    cmd="$cmd -n \"$name\""
    
    # Ajout des paramètres optionnels s'ils sont fournis
    [[ -n "$hostname" ]] && cmd="$cmd --hostname \"$hostname\""
    [[ -n "$ip_address" ]] && cmd="$cmd --ip-address \"$ip_address\""
    [[ -n "$memory" ]] && cmd="$cmd --memory $memory"
    [[ -n "$vcpu" ]] && cmd="$cmd --vcpu $vcpu"
    [[ -n "$os" ]] && cmd="$cmd --os \"$os\""
    [[ -n "$disks" ]] && cmd="$cmd --disks \"$disks\""
    [[ -n "$software" ]] && cmd="$cmd --software \"$software\""
    
    # Ajout des valeurs par défaut si configurées
    [[ -n "$DEFAULT_COMPANY" ]] && cmd="$cmd -c \"$DEFAULT_COMPANY\""
    [[ -n "$DEFAULT_LOCATION" ]] && cmd="$cmd -l \"$DEFAULT_LOCATION\""
    [[ -n "$DEFAULT_DEPARTMENT" ]] && cmd="$cmd -d \"$DEFAULT_DEPARTMENT\""
    [[ -n "$DEFAULT_SUPPLIER" ]] && cmd="$cmd -u \"$DEFAULT_SUPPLIER\""
    
    echo "Commande à exécuter :"
    echo "$cmd"
    echo
    
    read -p "Voulez-vous exécuter cette commande ? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        eval "$cmd"
    else
        echo "Commande annulée."
    fi
}

# Affichage de l'aide pour ce fichier de configuration
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "=== Fichier de configuration SnipeIT ==="
    echo
    echo "Ce fichier contient la configuration par défaut pour le script SnipeIT."
    echo
    echo "Utilisation :"
    echo "  source config.sh                    # Charger la configuration"
    echo "  source config.sh --help             # Afficher cette aide"
    echo "  source config.sh --check            # Vérifier la configuration"
    echo "  source config.sh --show-options     # Afficher les options courantes"
    echo
    echo "Fonctions disponibles après chargement :"
    echo "  show_common_options                 # Afficher les options courantes"
    echo "  check_config                        # Vérifier la configuration"
    echo "  create_asset_with_defaults          # Créer un asset avec les valeurs par défaut"
    echo
    exit 0
fi

# Vérification de la configuration si demandé
if [[ "$1" == "--check" ]]; then
    check_config
    exit $?
fi

# Affichage des options courantes si demandé
if [[ "$1" == "--show-options" ]]; then
    show_common_options
    exit 0
fi

# Vérification automatique de la configuration lors du chargement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce fichier doit être chargé avec 'source config.sh'"
    exit 1
fi

echo "Configuration SnipeIT chargée."
echo "Utilisez 'show_common_options' pour voir les options disponibles."
echo "Utilisez 'check_config' pour vérifier la configuration." 