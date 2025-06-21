#!/bin/bash

# Script d'installation pour SnipeIT Tools
# Ce script automatise l'installation et la configuration initiale

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_message() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
    esac
}

# Fonction pour détecter le système d'exploitation
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/redhat-release ]]; then
            echo "centos"
        elif [[ -f /etc/debian_version ]]; then
            echo "debian"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Fonction pour installer les dépendances
install_dependencies() {
    local os=$(detect_os)
    
    log_message "INFO" "Détection du système d'exploitation: $os"
    
    case $os in
        "centos")
            log_message "INFO" "Installation des dépendances sur CentOS/RHEL..."
            if command -v yum >/dev/null 2>&1; then
                sudo yum install -y curl jq
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y curl jq
            else
                log_message "ERROR" "Aucun gestionnaire de paquets compatible trouvé"
                return 1
            fi
            ;;
        "debian")
            log_message "INFO" "Installation des dépendances sur Debian/Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y curl jq
            ;;
        "macos")
            log_message "INFO" "Installation des dépendances sur macOS..."
            if command -v brew >/dev/null 2>&1; then
                brew install curl jq
            else
                log_message "ERROR" "Homebrew n'est pas installé. Veuillez l'installer d'abord."
                log_message "INFO" "Visitez https://brew.sh pour installer Homebrew"
                return 1
            fi
            ;;
        *)
            log_message "ERROR" "Système d'exploitation non supporté: $os"
            log_message "INFO" "Veuillez installer manuellement curl et jq"
            return 1
            ;;
    esac
    
    log_message "SUCCESS" "Dépendances installées avec succès"
}

# Fonction pour vérifier les dépendances
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "WARNING" "Dépendances manquantes: ${missing_deps[*]}"
        return 1
    fi
    
    log_message "SUCCESS" "Toutes les dépendances sont installées"
    return 0
}

# Fonction pour configurer l'environnement
configure_environment() {
    log_message "INFO" "Configuration de l'environnement SnipeIT..."
    
    # Vérifier si le fichier de configuration existe
    if [[ ! -f "config.sh" ]]; then
        log_message "ERROR" "Fichier config.sh non trouvé"
        return 1
    fi
    
    # Demander les informations de configuration
    echo
    echo "=== Configuration SnipeIT ==="
    echo
    
    read -p "URL du serveur SnipeIT (ex: https://snipeit.company.com): " snipeit_server
    read -p "Token API SnipeIT: " api_token
    echo
    
    read -p "Société par défaut (optionnel): " default_company
    read -p "Emplacement par défaut (optionnel): " default_location
    read -p "Département par défaut (optionnel): " default_department
    read -p "Fournisseur par défaut (optionnel): " default_supplier
    
    # Créer une sauvegarde du fichier de configuration
    cp config.sh config.sh.backup
    
    # Mettre à jour le fichier de configuration
    sed -i.bak "s|export SNIPEIT_SERVER=.*|export SNIPEIT_SERVER=\"$snipeit_server\"|" config.sh
    sed -i.bak "s|export API_TOKEN=.*|export API_TOKEN=\"$api_token\"|" config.sh
    
    if [[ -n "$default_company" ]]; then
        sed -i.bak "s|export DEFAULT_COMPANY=.*|export DEFAULT_COMPANY=\"$default_company\"|" config.sh
    fi
    
    if [[ -n "$default_location" ]]; then
        sed -i.bak "s|export DEFAULT_LOCATION=.*|export DEFAULT_LOCATION=\"$default_location\"|" config.sh
    fi
    
    if [[ -n "$default_department" ]]; then
        sed -i.bak "s|export DEFAULT_DEPARTMENT=.*|export DEFAULT_DEPARTMENT=\"$default_department\"|" config.sh
    fi
    
    if [[ -n "$default_supplier" ]]; then
        sed -i.bak "s|export DEFAULT_SUPPLIER=.*|export DEFAULT_SUPPLIER=\"$default_supplier\"|" config.sh
    fi
    
    # Supprimer les fichiers temporaires
    rm -f config.sh.bak
    
    log_message "SUCCESS" "Configuration mise à jour"
}

# Fonction pour tester la configuration
test_configuration() {
    log_message "INFO" "Test de la configuration..."
    
    # Charger la configuration
    source config.sh
    
    # Vérifier la configuration
    if ! ./config.sh --check; then
        log_message "ERROR" "Configuration invalide"
        return 1
    fi
    
    log_message "SUCCESS" "Configuration testée avec succès"
}

# Fonction pour afficher l'aide
show_help() {
    cat << EOF
Script d'installation pour SnipeIT Tools

Usage: $0 [OPTIONS]

OPTIONS:
    -i, --install-deps     Installer les dépendances
    -c, --configure        Configurer l'environnement
    -t, --test             Tester la configuration
    -a, --all              Installation complète (dépendances + configuration + test)
    -h, --help             Afficher cette aide

EXEMPLES:
    $0 --all               # Installation complète
    $0 --install-deps      # Installer seulement les dépendances
    $0 --configure         # Configurer seulement l'environnement
    $0 --test              # Tester seulement la configuration

EOF
}

# Fonction principale
main() {
    local install_deps=false
    local configure_env=false
    local test_config=false
    
    # Traitement des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--install-deps)
                install_deps=true
                shift
                ;;
            -c|--configure)
                configure_env=true
                shift
                ;;
            -t|--test)
                test_config=true
                shift
                ;;
            -a|--all)
                install_deps=true
                configure_env=true
                test_config=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_message "ERROR" "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Si aucune option n'est spécifiée, afficher l'aide
    if [[ "$install_deps" == "false" && "$configure_env" == "false" && "$test_config" == "false" ]]; then
        show_help
        exit 0
    fi
    
    log_message "INFO" "Démarrage de l'installation SnipeIT Tools"
    echo
    
    # Installation des dépendances
    if [[ "$install_deps" == "true" ]]; then
        log_message "INFO" "=== Étape 1: Installation des dépendances ==="
        if ! check_dependencies; then
            install_dependencies
        fi
        echo
    fi
    
    # Configuration de l'environnement
    if [[ "$configure_env" == "true" ]]; then
        log_message "INFO" "=== Étape 2: Configuration de l'environnement ==="
        configure_environment
        echo
    fi
    
    # Test de la configuration
    if [[ "$test_config" == "true" ]]; then
        log_message "INFO" "=== Étape 3: Test de la configuration ==="
        test_configuration
        echo
    fi
    
    log_message "SUCCESS" "Installation terminée avec succès !"
    echo
    echo "=== Prochaines étapes ==="
    echo "1. Charger la configuration: source config.sh"
    echo "2. Voir les exemples: ./example-usage.sh"
    echo "3. Créer un asset: ./snipeit-centos.sh -h"
    echo
}

# Exécution du script principal
main "$@" 