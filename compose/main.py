import os
import shutil
import time
from datetime import datetime, timedelta


def create_challenge_files(base_path):
    # Vérifier si le dossier de base existe, sinon le créer
    if not os.path.exists(base_path):
        os.makedirs(base_path)
        print(f"Dossier racine créé : {base_path}")
    else:
        print(f"Dossier racine déjà existant : {base_path}")

    # Fichiers mal nommés
    misnamed_files = [
        ("projet-secret_marc.pdf", "mauvais séparateur", "2024-03-01"),
        ("mariage.pdf", "petit piege de fichier dupliqué qui ne l'est pas", "2023-02-15"),
        ("c@r@ctere spec!aux.docx",
        "Fichier contenant des caractères spéciaux comme %, @ ou !.", "2024-03-10"),
        ("sans_extension", "Document sans extension, difficile à ouvrir.", "2024-01-20"),
        ("Résumé_reunion1012_2021.docx",
        "Résumé de données financières, avec des erreurs dans le nom.", "2023-04-01"),
        ("backup_db!.txt",
         "Sauvegarde avec des caractères illégaux dans le titre.", "2023-03-25"),
        ("photos été.jpg", "Une photo mal nommée, mélange d'espaces et de caractères spéciaux.", "2023-02-10"),
        ("Doc1", "Document inutile et très mal nommé.", "2023-03-05"),
        ("Doc2", "Document inutile et très mal nommé.", "2023-02-20"),
        ("Doc3", "Document inutile et très mal nommé.", "2023-01-15"),
        ("Doc4", "Document inutile et très mal nommé.", "2023-04-10"),
        ("Doc5", "Document inutile et très mal nommé.", "2023-03-30"),
        ("Doc6", "Document inutile et très mal nommé.", "2023-01-25"),
        ("Doc7", "Document inutile et très mal nommé.", "2023-04-05"),
        ("Doc8", "Document inutile et très mal nommé.", "2023-02-15"),
        ("Doc9", "Document inutile et très mal nommé.", "2023-01-10"),
        ("Doc10", "Document inutile et très mal nommé.", "2023-03-20"),
        ("Doc11", "Document inutile et très mal nommé.", "2023-03-05"),
        ("Doc12", "Document inutile et très mal nommé.", "2023-02-25"),
        ("Doc13", "Document inutile et très mal nommé.", "2023-01-05"),
        ("Doc14", "Document inutile et très mal nommé.", "2023-03-01"),
        ("Doc15", "Document inutile et très mal nommé.", "2023-02-10"),
        ("Doc16", "Document inutile et très mal nommé.", "2023-01-20"),
        ("Doc17", "Document inutile et très mal nommé.", "2023-04-01"),
        ("Doc18", "Document inutile et très mal nommé.", "2023-03-15"),
    ]


    correct_files = [
        ("facture_achats_mars_2023.pdf",
        "Facture d'achats pour le mois de mars 2023.", "2023-12-01"),
        ("rapport_activite_2022.docx",
        "Rapport complet des activités de l'année 2022.", "2024-11-25"),
        ("planning_reunion_equipe_2024.xlsx",
        "Planning de réunion d'équipe pour l'année 2024.", "2025-01-10"),
        ("notes_projet_alpha_2023.txt",
        "Notes sur le projet Alpha rédigées en 2023.", "2024-10-20"),
        ("liste_clients_premium_2024.csv",
        "Liste des clients premium avec leurs informations principales.", "2024-12-15"),
        ("budget_previsionnel_2025.pdf",
        "Document détaillant le budget prévisionnel de l'année 2024.", "2025-01-05"),
        ("proposition_commerciale_2023.pdf",
        "Proposition commerciale dupliquée, même contenu sur 2 fichiers.", "2023-12-25"),
        ("proposition_commerciale_2023 copie.pdf",
        "Proposition commerciale dupliquée, même contenu sur 2 fichiers.", "2023-12-25"),
    ]

    # Créer les fichiers mal nommés
    for name, content, date in misnamed_files:
            create_file(base_path, name, content, date)

    # Créer les fichiers correctement nommés
    for name, content, date in correct_files:
        create_file(base_path, name, content, date)


def create_file(folder_path, file_name, content, custom_date):
    file_path = os.path.join(folder_path, file_name)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)
    print(f"Fichier créé : {file_path}")

    set_file_timestamps(file_path, custom_date)


def set_file_timestamps(file_path, custom_date="2022-01-01"):
    """
    Modifie les dates de dernière modification et d'accès du fichier.
    """
    try:
        # Convertir la date en timestamp
        target_date = datetime.strptime(custom_date, "%Y-%m-%d")
        target_timestamp = time.mktime(target_date.timetuple())

        # Appliquer les nouveaux timestamps au fichier
        os.utime(file_path, (target_timestamp, target_timestamp))
        print(f"Métadonnées modifiées pour : {
              file_path} | Date définie : {custom_date}")
    except ValueError:
        print(f"Erreur : Format de date invalide pour '{
              custom_date}'. Utilisez 'YYYY-MM-DD'.")


def main():
    root_dir = "agent/test_data"
    create_challenge_files(root_dir)
    print("Espace Drive désorganisé local créé.")


# Exécuter le script
if __name__ == "__main__":
    main()
