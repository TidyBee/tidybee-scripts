import os
import shutil
import time


def create_challenge_files(base_path):
    # Vérifier si le dossier de base existe, sinon le créer
    if not os.path.exists(base_path):
        os.makedirs(base_path)
        print(f"Dossier racine créé : {base_path}")
    else:
        print(f"Dossier racine déjà existant : {base_path}")

    # Fichiers mal nommés
    misnamed_files = [
        ("projet-secret_marc.pdf", "mauvais séparateur"),
        ("mariage.pdf", "petit piege de fichier dupliqué qui ne l'est pas"),
        ("c@r@ctere spec!aux.docx",
         "Fichier contenant des caractères spéciaux comme %, @ ou !."),
        ("sans_extension", "Document sans extension, difficile à ouvrir."),
        ("Résumé_reunion1012_2021.docx",
         "Résumé de données financières, avec des erreurs dans le nom."),
        ("backup_db!.txt", "Sauvegarde avec des caractères illégaux dans le titre."),
        ("photos été.jpg",
         "Une photo mal nommée, mélange d'espaces et de caractères spéciaux."),
        ("Doc1", "Document inutile et très mal nommé."),
        ("Doc2", "Document inutile et très mal nommé."),
        ("Doc3", "Document inutile et très mal nommé."),
        ("Doc4", "Document inutile et très mal nommé."),
        ("Doc5", "Document inutile et très mal nommé."),
        ("Doc6", "Document inutile et très mal nommé."),
        ("Doc7", "Document inutile et très mal nommé."),
        ("Doc8", "Document inutile et très mal nommé."),
        ("Doc9", "Document inutile et très mal nommé."),
        ("Doc10", "Document inutile et très mal nommé."),
        ("Doc11", "Document inutile et très mal nommé."),
        ("Doc12", "Document inutile et très mal nommé."),
        ("Doc13", "Document inutile et très mal nommé."),
        ("Doc14", "Document inutile et très mal nommé."),
        ("Doc15", "Document inutile et très mal nommé."),
        ("Doc16", "Document inutile et très mal nommé."),
        ("Doc17", "Document inutile et très mal nommé."),
        ("Doc18", "Document inutile et très mal nommé."),
    ]

    # Fichiers correctement nommés
    correct_files = [
        ("facture_achats_mars_2023.pdf",
         "Facture d'achats pour le mois de mars 2023."),
        ("rapport_activite_2022.docx",
         "Rapport complet des activités de l'année 2022."),
        ("planning_reunion_equipe_2024.xlsx",
         "Planning de réunion d'équipe pour l'année 2024."),
        ("notes_projet_alpha_2023.txt", "Notes sur le projet Alpha rédigées en 2023."),
        ("liste_clients_premium_2024.csv",
         "Liste des clients premium avec leurs informations principales."),
        ("budget_previsionnel_2025.pdf",
         "Document détaillant le budget prévisionnel de l'année 2024."),
        ("proposition_commerciale_2023.pdf",
         "Proposition commerciale dupliquée, même contenu sur trois fichiers."),
        ("proposition_commerciale_2023 copie.pdf",
         "Proposition commerciale dupliquée, même contenu sur trois fichiers."),
    ]

    # Créer les fichiers mal nommés
    for name, content in misnamed_files:
        create_file(base_path, name, content)

    # Créer les fichiers correctement nommés
    for name, content in correct_files:
        create_file(base_path, name, content)


def create_file(folder_path, file_name, content, days_offset=8):
    file_path = os.path.join(folder_path, file_name)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)
    print(f"Fichier créé : {file_path}")

    if days_offset != 0:
        set_file_timestamps(file_path, days_offset)

def set_file_timestamps(file_path, days_offset):
    """
    Modifie les dates de dernière modification et d'accès du fichier.
    """
    # Calculer le timestamp en fonction du décalage en jours
    current_time = time.time()
    modified_time = current_time + abs(days_offset) * 24 * 60 * 60

    # Appliquer les nouveaux timestamps au fichier
    os.utime(file_path, (modified_time, modified_time))
    print(f"Métadonnées modifiées pour : {file_path} | Dernière utilisation : il y a {abs(days_offset)} jours.")

# Choisir le dossier racine
def main():
    root_dir = "agent/test_data"
    create_challenge_files(root_dir)
    print("Espace Drive désorganisé local créé.")


# Exécuter le script
if __name__ == "__main__":
    main()