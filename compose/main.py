import os


def create_challenge_files(base_path):
    # Vérifier si le dossier de base existe, sinon le créer
    if not os.path.exists(base_path):
        os.makedirs(base_path)
        print(f"Dossier racine créé : {base_path}")
    else:
        print(f"Dossier racine déjà existant : {base_path}")

    # Fichiers mal nommés
    misnamed_files = [
        ("projet.secret_marc.pdf", "Document sans aucune date."),
        ("doc_unique.pdf", "Document générique avec un titre très vague."),
        ("@liste_fourn!sseur_2023.docx",
         "Fichier contenant des caractères spéciaux comme %, @ ou !."),
        ("facture_amazon", "Document sans extension, difficile à ouvrir."),
        ("Résumé_reunion1012_2021.docx",
         "Résumé de données financières, avec des erreurs dans le nom."),
        ("backup!.txt", "Sauvegarde avec des caractères illégaux dans le titre."),
        ("photo vacances été.jpg",
         "Une photo mal nommée, mélange d'espaces et de caractères spéciaux."),
        ("ProjetFinal..doc",
         "Document de projet mal formaté avec double point dans le titre."),
        ("iEHSGIPSGHi", "Document inutile et très mal nommé."),
        ("Doc1", "Document inutile et très mal nommé."),
        ("Doc2", "Document inutile et très mal nommé."),
        ("Doc3", "Document inutile et très mal nommé."),
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