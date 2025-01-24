import os
import shutil



def create_challenge_files(base_path):
    if os.path.exists(base_path):
        shutil.rmtree(base_path)
        print(f"Contenu du dossier supprimé : {base_path}")
    os.makedirs(base_path)

    # Fichiers mal nommés
    misnamed_files = [
        ("projet-secret_marc.pdf", "mauvais séparateur"),
        ("photo_mariage_copie.pdf", "petit piege de fichier dupliqué qui ne l'est pas"),
        ("@liste_fourn!sseur_2023.docx",
         "Fichier contenant des caractères spéciaux comme %, @ ou !."),
        ("facture_amazon", "Document sans extension, difficile à ouvrir."),
        ("Résumé_reunion1012_2021.docx",
         "Résumé de données financières, avec des erreurs dans le nom."),
        ("backup_db!.txt", "Sauvegarde avec des caractères illégaux dans le titre."),
        ("photo vacances été.jpg",
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
    ]

    # Fichiers dupliqués
    duplicates = [
        ("proposition_commerciale_2023.pdf",
         "Proposition commerciale dupliquée, même contenu sur trois fichiers."),
        ("presentation$_projet_bet@_2022.pdf",
         "Présentation PowerPoint répétée plusieurs fois."),
    ]

    # Créer les fichiers mal nommés
    for name, content in misnamed_files:
        create_file(base_path, name, content)

    # Créer les fichiers correctement nommés
    for name, content in correct_files:
        create_file(base_path, name, content)

    # Créer les fichiers dupliqués (3 copies de chaque fichier)
    for name, content in duplicates:
        for i in range(3):
            create_file(base_path, f"{i+1}_{name}", content)


def create_file(folder_path, file_name, content):
    file_path = os.path.join(folder_path, file_name)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)
    print(f"Fichier créé : {file_path}")


# Choisir le dossier racine
def main():
    root_dir = "agent/test_data"
    create_challenge_files(root_dir)
    print("Espace Drive désorganisé local créé.")


# Exécuter le script
if __name__ == "__main__":
    main()