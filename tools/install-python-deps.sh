#!/bin/bash

# Script d'installation des dépendances Python pour SnipeIT Tools

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

# Fonction pour vérifier si Python est installé
check_python() {
    if command -v python3 >/dev/null 2>&1; then
        local version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_message "SUCCESS" "Python 3 trouvé: $version"
        return 0
    elif command -v python >/dev/null 2>&1; then
        local version=$(python --version 2>&1 | cut -d' ' -f2)
        if [[ "$version" =~ ^3\. ]]; then
            log_message "SUCCESS" "Python 3 trouvé: $version"
            return 0
        else
            log_message "ERROR" "Python 2 trouvé, Python 3 requis"
            return 1
        fi
    else
        log_message "ERROR" "Python 3 n'est pas installé"
        return 1
    fi
}

# Fonction pour vérifier si pip est installé
check_pip() {
    if command -v pip3 >/dev/null 2>&1; then
        log_message "SUCCESS" "pip3 trouvé"
        return 0
    elif command -v pip >/dev/null 2>&1; then
        log_message "SUCCESS" "pip trouvé"
        return 0
    else
        log_message "ERROR" "pip n'est pas installé"
        return 1
    fi
}

# Fonction pour installer les dépendances
install_dependencies() {
    log_message "INFO" "Installation des dépendances Python..."
    
    if [[ -f "requirements.txt" ]]; then
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install -r requirements.txt
        elif command -v pip >/dev/null 2>&1; then
            pip install -r requirements.txt
        else
            log_message "ERROR" "pip non trouvé"
            return 1
        fi
    else
        log_message "WARNING" "Fichier requirements.txt non trouvé, installation manuelle..."
        
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install requests rich
        elif command -v pip >/dev/null 2>&1; then
            pip install requests rich
        else
            log_message "ERROR" "pip non trouvé"
            return 1
        fi
    fi
    
    log_message "SUCCESS" "Dépendances Python installées avec succès"
}

# Fonction pour tester l'installation
test_installation() {
    log_message "INFO" "Test de l'installation..."
    
    if python3 -c "import requests, rich; print('✅ Toutes les dépendances sont installées')" 2>/dev/null; then
        log_message "SUCCESS" "Test réussi"
        return 0
    else
        log_message "ERROR" "Test échoué - certaines dépendances manquent"
        return 1
    fi
}

# Fonction pour afficher l'aide
show_help() {
    cat << EOF
Script d'installation des dépendances Python pour SnipeIT Tools

Usage: $0 [OPTIONS]

OPTIONS:
    -i, --install         Installer les dépendances
    -t, --test            Tester l'installation
    -a, --all             Installation complète + test
    -h, --help            Afficher cette aide

EXEMPLES:
    $0 --all              # Installation complète
    $0 --install          # Installer seulement les dépendances
    $0 --test             # Tester seulement l'installation

DEPENDANCES:
    - requests>=2.28.0    # Pour les appels HTTP
    - rich>=12.0.0        # Pour l'affichage coloré

EOF
}

# Fonction principale
main() {
    local install_deps=false
    local test_install=false
    
    # Traitement des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--install)
                install_deps=true
                shift
                ;;
            -t|--test)
                test_install=true
                shift
                ;;
            -a|--all)
                install_deps=true
                test_install=true
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
    if [[ "$install_deps" == "false" && "$test_install" == "false" ]]; then
        show_help
        exit 0
    fi
    
    log_message "INFO" "Démarrage de l'installation des dépendances Python"
    echo
    
    # Vérification de Python
    log_message "INFO" "=== Étape 1: Vérification de Python ==="
    if ! check_python; then
        log_message "ERROR" "Python 3 requis mais non trouvé"
        log_message "INFO" "Veuillez installer Python 3 depuis https://python.org"
        exit 1
    fi
    echo
    
    # Vérification de pip
    log_message "INFO" "=== Étape 2: Vérification de pip ==="
    if ! check_pip; then
        log_message "ERROR" "pip requis mais non trouvé"
        log_message "INFO" "Veuillez installer pip avec votre gestionnaire de paquets"
        exit 1
    fi
    echo
    
    # Installation des dépendances
    if [[ "$install_deps" == "true" ]]; then
        log_message "INFO" "=== Étape 3: Installation des dépendances ==="
        if ! install_dependencies; then
            log_message "ERROR" "Échec de l'installation des dépendances"
            exit 1
        fi
        echo
    fi
    
    # Test de l'installation
    if [[ "$test_install" == "true" ]]; then
        log_message "INFO" "=== Étape 4: Test de l'installation ==="
        if ! test_installation; then
            log_message "ERROR" "Test d'installation échoué"
            exit 1
        fi
        echo
    fi
    
    log_message "SUCCESS" "Installation terminée avec succès !"
    echo
    echo "=== Prochaines étapes ==="
    echo "1. Testez le script: python3 list-settings.py -h"
    echo "2. Utilisez le script: python3 list-settings.py -s URL -t TOKEN"
    echo
}

# Exécution du script principal
main "$@" 