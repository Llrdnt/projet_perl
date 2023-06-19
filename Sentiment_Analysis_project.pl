#! /usr/bin/perl
#=====================================================
# Script : Sentiment_Analysis_project.pl
# Auteur : Loïc Laridant <loic.laridant@student.uclouvain.be>
# Date   : 17/06/2023
# Numérotation projet : 1/3
#=====================================================
# Usage  : perl Sentiment_Analysis_project.pl [Chemin jusque la qase de données textuelles] [-FR, -EN] [-global,-category]
#=====================================================
# Exigences : 
#   - Installation du module GD::Graph::bars
#   - Accès aux documents (devant se trouver dans le même répertoire) :
#       - Scripts_secondaires//analyse_global.pl
#       - Scripts_secondaires//analyse_category.pl
#       - Lexiques_emotions//emotions_EN.txt
#       - Lexiques_emotions//emotions_FR.txt
#       - category.txt
#       - style.css
#=====================================================
# Informations : Ce programme est basé sur deux "sous-programmes" (la description de chacun d'entre eux est accessible dans les documents correspondants)
# L'objectif est d'effectuer une analyse de sentiments des termes mentionnés dans du contenu textuel. Pour ce faire, le script va analyser ligne
# par ligne, les sentiments évoqués dans le contenu textuel concerné. 
# L'analyse est effectuée sur base de deux lexiques de valence émotionnelle :  
#      - Ce lexique francophone (reprenant 1286 termes) : http://www.lexique.org/?page_id=492 
#      - Ce lexique anglophone (reprenant 14'177 termes) :https://doi.org/10.4224/21270984
# 
# L'analyse peut-être effectuée sur des données textuelles anglophones (paramètre -EN) ou francophone (paramètre -FR). 
# Selon le mode sélectionné (-global ou -category), le script calculera le score de chaque émotion étudiée sur l'ensemble des lignes (mode global)
# ou uniquement sur les tweets comprenant un terme mentionné dans le document category.txt.
#
# En sortie, le programme générera un rapport .html présentant des représentations graphiques des analyses effectuées (ainsi qu'une série de graphiques au format .png).
# Il nous retournera également (dans le rapport .html), pour chaque émotion, la ligne ayant le score le plus élevé. 
#=====================================================
use strict;                                                                                                 #initialisation des modules 'stricts' et 'warnings'
use warnings;

my $content_db = $ARGV[0];                                                                                  #récupération en argument de la base de données textuelles à analyser
my $lang = $ARGV[1];                                                                                        #récupération en argument de la langue utilisée pour l'analyse
my $mode = $ARGV[2];                                                                                        #récupération en argument du mode utilisé pour l'analyse


if ($lang ne '-FR' and $lang ne '-EN'){
    print "Langue non prise en compte par le programme, veuillez spécifier si votre corpus est rédigé en anglais (-EN) ou en français (-FR). \n";           #vérification de la prise en charge de langue mentionnée
}
else{
    if ($mode ne '-global' and $mode ne '-category' ){
        print "Mode non pris en compte par le programme, veuillez spécifier si vous voulez effectuer une analyse globale (-global) ou par médias (-category). \n"; #vérification de la prise en charge du mode mentionné
    }
    else{                                                                                                                                                     #lancement des scripts secondaires (si les conditions sont satisfaites)
        if ($lang eq "-FR" and $mode eq "-global"){                                                                                                           #sur base des arguments mentionnés.
            print "Lancement de l'analyse globale d'un corpus francophone. \n";                                                                                                          
            system("perl Scripts_secondaires//analyse_global.pl $content_db Lexiques_emotions//emotions_FR.txt");
        }

        if ($lang eq "-EN" and $mode eq "-global"){
            print "Lancement de l'analyse globale d'un corpus anglophone. \n";
            system("perl Scripts_secondaires//analyse_global.pl $content_db Lexiques_emotions//emotions_EN.txt");
        }

        if ($lang eq "-FR" and $mode eq "-category"){
            print "Lancement de l'analyse en mode 'media' d'un corpus francophone. \n";
            system("perl Scripts_secondaires//analyse_category.pl $content_db Lexiques_emotions//emotions_FR.txt");
        }

        if ($lang eq "-EN" and $mode eq "-category"){
            print "Lancement de l'analyse en mode 'media' d'un corpus anglophone. \n";
            system("perl Scripts_secondaires//analyse_category.pl $content_db Lexiques_emotions//emotions_EN.txt");
        }
    }
}
