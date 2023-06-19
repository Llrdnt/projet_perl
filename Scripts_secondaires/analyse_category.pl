#! /usr/bin/perl
#=====================================================
# Script : Sentiment_Analysis_project.pl
# Auteur : Loïc Laridant <loic.laridant@student.uclouvain.be>
# Date   : 17/06/2023
# Numérotation projet : 3/3
#=====================================================
# Usage  : perl analyse_media.pl [Chemin jusque la qase de données textuelles] [Chemin jusqu'au lexique des émotions]
#=====================================================
# Exigences : 
#   - Installation du module GD::Graph::bars
#   - Accès aux documents (devant se trouver dans le même répertoire) :
#       - Lexiques_emotions//emotions_EN.txt
#       - Lexiques_emotions//emotions_FR.txt
#       - category.txt (structure définie dans le document read.me)
#       - style.css
#=====================================================
# Informations : Ce script secondaire va nous permettre d'analyser les émotions évoquées dans les lignes de texte comprenant uen mention à un
# terme compris dans le document category.txt.
# 
# # L'analyse est effectuée sur base de deux lexiques de valence émotionnelle (à préciser en argument selon la langue utilisée dans le corpus) :  
#      - Un lexique francophone (reprenant 1286 termes) : http://www.lexique.org/?page_id=492 
#      - Un lexique anglophone (reprenant 14'177 termes) :https://doi.org/10.4224/21270984
#
# En sortie, le programme générera un rapport .html présentant des représentations graphiques des analyses effectuées (ainsi qu'une série de graphiques au format .png).
# Il nous retournera également (dans le rapport .html), pour chaque émotion, la ligne ayant le score le plus élevé. 
#=====================================================

use strict;                                                                                                                      #importation des modules généraux
use warnings;

use utf8;                                                                                                                        #importation des modules nécessaires à l'encodage des termes
use Encode qw(encode decode);
use open qw(:std :utf8);

use GD::Graph::bars;                                                                                                             #importation des modules nécessaires à la création des graphiques au format .png
use GD::Graph::Data;

###############################################################################################################
# CREATION DES TABLES DE HACHAGES NECESSAIRES A' L'ANALYSE

my %emotion_global;                                                                                                              #création d'une table de hachage reprenant, pour chaque catégorie, les 5 termes mentionnés
open(my $fichier_media, '<', 'category.txt') or die "Impossible d'ouvrir le fichier : $!";
binmode $fichier_media, ':encoding(UTF-8)';                                                                                      #spécification de l'encodage utilisé pour la lecture du document à analyser
while (my $line = <$fichier_media>) {
    chomp $line;
    my @info = split('#', $line);                                                                                                #séparation des informations mentionnées dans le document category.txt selon la structure définie dans read.me
    my @temp_list = split ("%%",$info[1]);
    if (scalar @temp_list != 5){
      print "Attention, il n y'a pas 5 termes mentionnés pour la catégorie : $info[0] (veuillez vérifier le document category.txt) ! \n";#impression d'un message d'erreur s'il n'y a pas 5 médias mentionnés pour un catégorie
    }
    my @insert_list = (0,0,0,0,0,0,0,0,0);                                                                                       #insertion, dans la valeur du dictionnaire, d'une liste de valeurs représentant le score de chaque émotion étudiée
    unshift @insert_list, \@temp_list;
    $emotion_global{$info[0]} = \@insert_list ;                            
}

print "Table de hachage des termes (par catégorie) créée. \n";

my %word_emotion;                                                                                                                #création d'une table de hachage sur base du lexique mentionné en argument 
my $word_emotion_document =$ARGV[1];
open(my $fichier_word_emotion, '<', $word_emotion_document) or die "Impossible d'ouvrir le fichier : $!";
binmode $fichier_word_emotion, ':encoding(UTF-8)';                                                                               #spécification de l'encodage utilisé pour la lecture du document
while (my $line = <$fichier_word_emotion>) {
    chomp $line;
    my @temp_list = split('_', $line);                                                                                           #séparation des informations mentionnées dans le document sur bas du caractère "_"
    $word_emotion{$temp_list[0]} = [$temp_list[1],$temp_list[2],$temp_list[3],$temp_list[4],$temp_list[5],$temp_list[6],$temp_list[7],$temp_list[8]];
}

print "Table de hachage des émotions créée. \n";

###############################################################################################################
# ANALYSE DU CONTENU DU DOCUMENT COMPRENANT LES DONNEES TEXTUELLES

my $tweet_content_document =$ARGV[0];                                                                                            #récupération des données comprises dans le document à analyser (mentionné en argument)                                           
open(my $fichier_tweet_content, '<', $tweet_content_document) or die "Impossible d'ouvrir le fichier : $!";
binmode $fichier_tweet_content, ':encoding(UTF-8)';                                                                              #spécification de l'encodage utilisé pour la lecture du document à analyser
my %emotion_temp;                                                                                                                #création d'une table de hachage temporaire nous permettant d'enregistrer les valeurs pour une ligne (ce dictionnaire sera réinitialisé à chaque itération/chaque ligne)                                                                                                               
my $max_joy = 0;                                                                                                                 #création de variables nous permettant d'enregistrer les lignes ayant le score le plus élevé pour chaque émotion
my $text_max_joy = "";
my $max_surprise = 0;
my $text_max_surprise = "";
my $max_anger = 0;
my $text_max_anger = "";
my $max_disgust = 0;
my $text_max_disgust = "";
my $max_fear = 0;
my $text_max_fear = "";
my $max_sadness = 0;
my $text_max_sadness = "";
my $max_pos = 0;
my $text_max_pos = "";
my $max_neg = 0;
my $text_max_neg = "";
while (my $line = <$fichier_tweet_content>){                                                                                     #ouverture du document              
    chomp $line;
    my $flag = 0;                                                                                                                #création d'une variable flag qui nous permettra de vérifier si une ligne comprend une mention à un média ou pas
    my @word_tweet_list = split (" ",$line);
    my %emotion_temp;
    foreach my $category_keys (keys %emotion_global) {                                                                            #pour chaque catégorie étudiée (et donc mentionné dans le dictionnaire %emotion_global)
        $emotion_temp{$category_keys} = [0,0,0,0,0,0,0,0,0];                                                                      #nous créons une nouvelle clef dans le dictionnaire temporaire 
        my $category_info = $emotion_global{$category_keys};                                                                       #en encodant en valeur une liste de valeurs correspondantes aus émotions étudiées                                                               
        my @category_info_dereference = @{$category_info};
        my @media_list = @{$category_info_dereference[0]};                                                                        #récupération de la liste des médias (utilisation d'un procédé de déréférencement pour récupérer les données dans un objet 'ARRAY')
        foreach my $media (@media_list) {
           my @temp_list = grep(/$media/,@word_tweet_list);                                                                      #vérification, à l'aide d'un commande 'grep', si un média est mentionné dans le tweet
                    if (scalar (@temp_list)==0){
                        $flag = 0;                                                                                               #si aucun média n'est localisé -> la variable 'flag' reste à 0
                    }
                    else {
                        $flag = 1;                                                                                               #si un média est localisé -> la variable 'flag' prend 1 comme valeur et on sort de la boucle 
                        last;
                    }
        }
                if ($flag == 1) {                                                                                                #si la variable 'flag' == 1, le programme met à jour les valeurs des émotions (pour la ligne)
                    foreach my $word_tweet (@word_tweet_list){                                                                   #itération par terme 
                        if (exists $word_emotion{$word_tweet}){                                                                  #vérification si le terme itéré apparaît dans le dictionnaire des émotions
                            $emotion_temp{$category_keys}[0]+=$word_emotion{$word_tweet}[0];                                      #joie
                            $emotion_temp{$category_keys}[1]+=$word_emotion{$word_tweet}[1];                                      #surprise
                            $emotion_temp{$category_keys}[2]+=$word_emotion{$word_tweet}[2];                                      #colère
                            $emotion_temp{$category_keys}[3]+=$word_emotion{$word_tweet}[3];                                      #dégoût
                            $emotion_temp{$category_keys}[4]+=$word_emotion{$word_tweet}[4];                                      #peur
                            $emotion_temp{$category_keys}[5]+=$word_emotion{$word_tweet}[5];                                      #tristesse
                            $emotion_temp{$category_keys}[6]+=$word_emotion{$word_tweet}[6];                                      #positif
                            $emotion_temp{$category_keys}[7]+=$word_emotion{$word_tweet}[2];                                      #négatif
                            $emotion_temp{$category_keys}[8]+=1;                                                                  #compteur qui nous permettra d'effectuer la moyenne générale par ligne
                        }
                    }
                    if ($emotion_temp{$category_keys}[8] == 0){                                                                   #dans le cas où aucune ligne n'aurait été analysée, l'on donne 1 comme valeur au compteur
                        $emotion_temp{$category_keys}[8]+=1;                                                                      #(afin d'éviter une division par 0 - une division par 1 n'ayant pas d'effet)
                    }
                    if ($emotion_temp{$category_keys}[8] != 1){                                                          
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[0]/$emotion_temp{$category_keys}[8]))>$max_joy){         #pour chaque émotion, l'on va vérifier si le score de la ligne est supérieur au maximum enregistré
                            $max_joy=sprintf("%.2f",($emotion_temp{$category_keys}[0]/$emotion_temp{$category_keys}[8]));          #si oui, les variables de maximum et celle enregistrant la ligne seront mises à jour (sinon ça passe)
                            $text_max_joy = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[1]/$emotion_temp{$category_keys}[8]))>$max_surprise){    #utilisation de la fonction sprintf("%.2f",... pour créer des nombres arrondis à 2 décimales
                            $max_surprise=sprintf("%.2f",($emotion_temp{$category_keys}[1]/$emotion_temp{$category_keys}[8]));
                            $text_max_surprise = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[2]/$emotion_temp{$category_keys}[8]))>$max_anger){
                            $max_anger = sprintf("%.2f",($emotion_temp{$category_keys}[2]/$emotion_temp{$category_keys}[8]));
                            $text_max_anger = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[3]/$emotion_temp{$category_keys}[8]))>$max_disgust){
                            $max_disgust = sprintf("%.2f",($emotion_temp{$category_keys}[3]/$emotion_temp{$category_keys}[8]));
                            $text_max_disgust = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[4]/$emotion_temp{$category_keys}[8]))>$max_fear){
                            $max_fear = sprintf("%.2f",($emotion_temp{$category_keys}[4]/$emotion_temp{$category_keys}[8]));
                            $text_max_fear = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[5]/$emotion_temp{$category_keys}[8]))>$max_sadness){
                            $max_sadness = sprintf("%.2f",($emotion_temp{$category_keys}[5]/$emotion_temp{$category_keys}[8]));
                            $text_max_sadness = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[6]/$emotion_temp{$category_keys}[8]))>$max_pos){
                            $max_pos = sprintf("%.2f",($emotion_temp{$category_keys}[6]/$emotion_temp{$category_keys}[8]));
                            $text_max_pos = $line;
                        }
                        if (sprintf("%.2f",($emotion_temp{$category_keys}[7]/$emotion_temp{$category_keys}[8]))>$max_neg){
                            $max_neg = sprintf("%.2f",($emotion_temp{$category_keys}[7]/$emotion_temp{$category_keys}[8]));
                            $text_max_neg = $line;
                        }
                    }
                    $emotion_global{$category_keys}[1]+=($emotion_temp{$category_keys}[0]/$emotion_temp{$category_keys}[8]);        #après l'analyse de tous les termes d'une ligne, de la mise à jour des variables de maximum (cf. dernier commentaire)
                    $emotion_global{$category_keys}[2]+=($emotion_temp{$category_keys}[1]/$emotion_temp{$category_keys}[8]);        #le programme met à jour le dictionnaire global (%emotion_global)  en effectuant une moyenne générale des scores par ligne
                    $emotion_global{$category_keys}[3]+=($emotion_temp{$category_keys}[2]/$emotion_temp{$category_keys}[8]);        #à l'aide du compteur ($emotion_temp{$category_keys}[8])
                    $emotion_global{$category_keys}[4]+=($emotion_temp{$category_keys}[3]/$emotion_temp{$category_keys}[8]);
                    $emotion_global{$category_keys}[5]+=($emotion_temp{$category_keys}[4]/$emotion_temp{$category_keys}[8]);
                    $emotion_global{$category_keys}[6]+=($emotion_temp{$category_keys}[5]/$emotion_temp{$category_keys}[8]);
                    $emotion_global{$category_keys}[7]+=($emotion_temp{$category_keys}[6]/$emotion_temp{$category_keys}[8]);
                    $emotion_global{$category_keys}[8]+=($emotion_temp{$category_keys}[7]/$emotion_temp{$category_keys}[8]);
                    $emotion_global{$category_keys}[9]+=1;                                                                        #création d'un compteur (représentant le nombre de lignes analysées) nécessaire au calcul ultérieur de la moyenne globale 
                }
    if ($emotion_global{$category_keys}[9] == 0){                                                                                 #dans le cas-où aucune ligne n'aurait été analysée, l'on donne 1 comme valeur au compteur
        $emotion_global{$category_keys}[9]+=1;                                                                                    #(afin d'éviter une division par 0 - une division par 1 n'ayant pas d'effet)
    }
}
}

print "Analyse du corpus effectuée.\n";
###############################################################################################################
# CREATION DES GRAPHIQUES PAR CATEGORIE
print "Création des représentations graphiques (.png).\n";

my @gen_graph_keys = keys %emotion_global;                                                                                       #création des listes nécessaires à la création du graphique compteur et du graphique général 'positif/négatif' suivant
my @gen_pos_val = ();
my @gen_neg_val = ();
my @gen_count = ();
foreach my $category_keys (keys %emotion_global) {                                                                                #création d'un graphique par catégorie pour représenter les émotions (hors négatif et positif)
    push @gen_pos_val, ($emotion_global{$category_keys}[7] / $emotion_global{$category_keys}[9]);
    push @gen_neg_val, ($emotion_global{$category_keys}[8] / $emotion_global{$category_keys}[9]);
    push @gen_count, ($emotion_global{$category_keys}[9]);
    my $data = GD::Graph::Data->new([                                                                                            #initialisation de l'objet 'graph' et des valeurs (calcul de la moyenne par sentiment à l'aide du compteur $emotion_global{$category_keys}[9])
        ['joy','surprise','anger','disgust','fear','sadness'],
        [($emotion_global{$category_keys}[1] / $emotion_global{$category_keys}[9]), ($emotion_global{$category_keys}[2] / $emotion_global{$category_keys}[9]), ($emotion_global{$category_keys}[3] / $emotion_global{$category_keys}[9]), ($emotion_global{$category_keys}[4] / $emotion_global{$category_keys}[9]), ($emotion_global{$category_keys}[5] / $emotion_global{$category_keys}[9]), ($emotion_global{$category_keys}[6] / $emotion_global{$category_keys}[9])]
    ]);

    my $graph = GD::Graph::bars->new(700, 500);                                                                                  #création de la représentation (format, labels, titre, maximum, ...)
    $graph->set(
        x_label    => 'Sentiment',
        x_label_font_size => 50,
        y_label    => 'Pourcentage moyen par ligne',
        y_max_value => 20,
        title      => "Graphique $category_keys"
    );

    open my $png1, '>', "Graphiques\\graph_$category_keys.png";                                                                   #impression du graphique (sur base des listes de données mentionnées) dans un document au format.png
    binmode $png1;
    print $png1 $graph->plot($data)->png;
    close $png1;

}

###############################################################################################################
# CREATION DU GRAPHIQUE POSITIF/NEGATIF GENERAL

my @datagen =(\@gen_graph_keys,\@gen_pos_val,\@gen_neg_val);                                                                     #création d'un graphique représentant le score négatif et positif par catégorie étudié

 my $graphgen = GD::Graph::bars->new (700,500);                                                                                  #création de la représentation (format, labels, titre, maximum, ...)
    $graphgen -> set (
        x_label    => 'Comparaison du % de positivité et de négativité étpouvé', 
        y_label    => 'Sentiment éprouvé',
        dclrs => ['green', 'red'],
        title      => "Graphique général"
    );

    $graphgen->plot(\@datagen);                                                                                                  #intégration des listes de données dans le graphique

    open my $png2, '>', "Graphiques\\graph_general_posneg.png";                                                                  #impression du graphique dans un document au format.png
    binmode $png2;
    print $png2 $graphgen->gd->png;
    close $png2;

###############################################################################################################
# CREATION DU GRAPHIQUE COUNTER

my @datagen_count =(\@gen_graph_keys,\@gen_count);                                                                               #création d'une liste de listes pour représenter le nombre de lignes analysées par catégorie (graphique compteur)

my $graphgen_count = GD::Graph::bars->new (700,500);                                                                             #création de la représentation (format, labels, titre, maximum, ...)
    $graphgen_count -> set (
        x_label    => 'Catégorie',
        y_label    => 'Nombre de tweets analysés',
        dclrs => ['blue'],
        title      => "Composition du corpus d'analyse"
    );

    $graphgen_count->plot(\@datagen_count);                                                                                      #intégration des listes de données dans le graphique

    open my $png3, '>', "Graphiques\\graph_general_count.png";                                                                   #impression du graphique dans un document au format.png
    binmode $png3;  
    print $png3 $graphgen_count->gd->png;
    close $png3;


###############################################################################################################
# CREATION D'UN RAPPORT EN HTML - COMPOSITION DE L'ANALYSE
print "Création du rapport .html. \n";                                                                                           #création de la structure du document .html (header & balise script) - Intégration des données de l'analyse dans des graphiques proposées par Google Chart.
my $analyse_country_head = "                                                                                                        
<html>
  <head>
    <link rel='stylesheet' href='style.css'>
    <script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>
    <script type='text/javascript'>
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Catégorie', 'Nombre de lignes analysés'],
";
foreach my $category_keys (keys %emotion_global){                                                                                 #pour chaque pays étudié, on ajoutera une liste de données dans le graphique                            
    my $count = $emotion_global{$category_keys}[9];
    my $country_val = "'".$category_keys."'";
    $analyse_country_head = $analyse_country_head."[$country_val,$count]";
    if ($category_keys eq (keys %emotion_global)[-1]){
        last;
    }
    else{
        $analyse_country_head = $analyse_country_head.",";                                                                       #élément de structure 
    }
}

$analyse_country_head = $analyse_country_head."
]);

        var options = {
          title: 'Nombre de lignes analysées par catégorie'
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart'));

        chart.draw(data, options);
      }
    </script>
";

# Création de la balise "body".
my $analyse_country_body = "
<body>
    <h2>Rapport d'analyse des sentiments d'un corpus de données textuelles (ligne par ligne)</h2>
    <p>
    Ce rapport a été généré à l'aide du programme codé en perl accessible sur <a href='https://github.com/Llrdnt/projet_perl'>ce répositoire</a>.
    L'objectif de ce projet est d'effectuer une analyse des sentiments des tweets publiés entre janvier 2016 et novembre 2022 comprenant le '#MeToo' et une 
    mention à un média étudié (voir document 'category.txt'). 

    L'idée est de mettre en évidence les sentiments évoqués par les utilisateurs lorsqu'ils mentionnent le compte d'un média. Cette analyse est basée sur un lexique de 1286 mots.
    Cette base de données créée par Gobin, P., Camblats, A. M., Faurous, W., & Mathey, S. est accessible via <a href='http://www.lexique.org/?page_id=492'>ce lien</a>.

    Ce rapport présentera :
    <ul>
        <li> Une présentation du nombre de tweets (lignes) étudiés par catégorie</li>
        <li> Une analyse des sentiments positifs évoqués (sentiment positif 'général', joie et surprise)</li>
        <li> Une analyse des sentiments négatifs évoqués (sentiment négatif 'général', peur, tristesse, colère et dégoût)</li>
        <li> Une présentation des lignes (tweets) ayant le score le plus élevé pour chaque émotion </li>
    </ul>
    </p>
    <div id='piechart' class = 'graph' ></div>
    <hr>
";

###############################################################################################################
# CREATION D'UN RAPPORT EN HTML - ANALYSE POSITIVE
# Ajout (dans le header et dans le body) des informations sur le graphique d'analyse des sentiments positifs (balise script).

$analyse_country_head = $analyse_country_head."
    <script type='text/javascript'>
      google.charts.load('current', {'packages':['bar']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable([
        ['Catégorie', 'Positif', 'Joie', 'Surprise'],
";

foreach my $category_keys (keys %emotion_global){
    my $joie = ($emotion_global{$category_keys}[1]/$emotion_global{$category_keys}[9]);
    my $surprise = ($emotion_global{$category_keys}[2]/$emotion_global{$category_keys}[9]);
    my $positif = ($emotion_global{$category_keys}[7]/$emotion_global{$category_keys}[9]);
    my $country_val = "'".$category_keys."'";
    $analyse_country_head = $analyse_country_head."[$country_val,$joie,$surprise,$positif]";
    if ($category_keys eq (keys %emotion_global)[-1]){
        last;
    }
    else{
        $analyse_country_head = $analyse_country_head.",";
    }
}

$analyse_country_head = $analyse_country_head."
]);

        var options = {
          chart: {
            title: 'Analyse des sentiments positifs par catégorie',
            subtitle: 'Pour les lignes (tweets) comprenant une mention à un média étudié et le terme #MeToo',
          },
          bars: 'horizontal' // Required for Material Bar Charts.
        };

        var chart = new google.charts.Bar(document.getElementById('barchart_material_pos'));

        chart.draw(data, google.charts.Bar.convertOptions(options));
      }
    </script>
";

# Ajout dans le <body> du graphique créé.

$analyse_country_body = $analyse_country_body."
    <div id='barchart_material_pos' class = 'graph'></div>
    <hr>
";

###############################################################################################################
# CREATION D'UN RAPPORT EN HTML - ANALYSE NEGATIVE
# Ajout (dans le header et dans le body) des informations sur le graphique d'analyse des sentiments négatifs (balise script)

$analyse_country_head = $analyse_country_head."
    <script type='text/javascript'>
      google.charts.load('current', {'packages':['bar']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable([
        ['Catégorie', 'Négatif', 'Colère', 'Dégout','Peur','Tristesse'],
";

foreach my $category_keys (keys %emotion_global){
    my $negatif = ($emotion_global{$category_keys}[8]/$emotion_global{$category_keys}[9]);
    my $tristesse = ($emotion_global{$category_keys}[6]/$emotion_global{$category_keys}[9]);
    my $peur = ($emotion_global{$category_keys}[5]/$emotion_global{$category_keys}[9]);
    my $degout = ($emotion_global{$category_keys}[4]/$emotion_global{$category_keys}[9]);
    my $colere= ($emotion_global{$category_keys}[3]/$emotion_global{$category_keys}[9]);
    my $country_val = "'".$category_keys."'";
    $analyse_country_head = $analyse_country_head."[$country_val,$negatif,$colere,$degout,$peur,$tristesse]";
    if ($category_keys eq (keys %emotion_global)[-1]){
        last;
    }
    else{
        $analyse_country_head = $analyse_country_head.",";
    }
}

$analyse_country_head = $analyse_country_head."
]);

        var options = {
          chart: {
            title: 'Analyse des sentiments négatifs par catégorie',
            subtitle: 'Pour les lignes (tweets) comprenant une mention à un média étudié et le terme #MeToo',
          },
          bars: 'horizontal' // Required for Material Bar Charts.
        };

        var chart = new google.charts.Bar(document.getElementById('barchart_material_neg'));

        chart.draw(data, google.charts.Bar.convertOptions(options));
      }
    </script>
";
$analyse_country_head = $analyse_country_head."</head>";

# Ajout dans le <body> du graphique créé.

$analyse_country_body = $analyse_country_body."
    <div id='barchart_material_neg' class = 'graph'></div>
    <hr>
";

###############################################################################################################
# CREATION D'UN RAPPORT EN HTML - ANALYSE NEGATIVE
# Présentation des lignes ayant le score le plus élevé pour chaque ligne dans un tableau (sur base des valeurs calculées précédemment). 
$analyse_country_body = $analyse_country_body."
<div class='top'>
  <h1>Présentation des lignes (tweets) ayant le plus haut score pour chaque émotion étudiée</h1>
  <p>
    Plus précisément, notre analyse est basée sur 8 émotions:
    <ul>
      <li>La joie</li>
      <li>La surprise</li>
      <li>La colère</li>
      <li>Le dégoût</li>
      <li>La peur</li>
      <li>La tristesse</li>
      <li>Sentiment positif</li>
      <li>Sentiment négatif</li>
    </ul>
    Chaque ligne obtiendra un certain score (pourcentage) pour chaque émotion en fonction des termes y étant évoqués.
    Nous allons nous intéresser aux lignes (tweets) ayant le score le plus élevé pour chaque émotion. 
  </p>
  <table id='customers'>
    <tr>
        <th>Émotions</th>
        <th>Ligne</th>
        <th>Score (%)</th>
    </tr>
    <tr>
        <td>Joie</td>
        <td>$text_max_joy</td>
        <td>$max_joy</td>
    </tr>
    <tr>
      <td>Surprise</td>
      <td>$text_max_surprise</td>
      <td>$max_surprise</td>
    </tr>
    <tr>
      <td>Colère</td>
      <td>$text_max_anger</td>
      <td>$max_anger</td>
    </tr>
    <tr>
      <td>Dégoût</td>
      <td>$text_max_disgust</td>
      <td>$max_disgust</td>
    </tr>
    <tr>
      <td>Peur</td>
      <td>$text_max_fear</td>
      <td>$max_fear</td>
    </tr>
    <tr>
      <td>Tristesse</td>
      <td>$text_max_sadness</td>
      <td>$max_sadness</td>
    </tr>
    <tr>
      <td>Positif</td>
      <td>$text_max_pos</td>
      <td>$max_pos</td>
    </tr>
    <tr>
      <td>Négatif</td>
      <td>$text_max_neg</td>
      <td>$max_neg</td>
    </tr>
</div>
";

# Fermeture de la balise <html> pour conclure le document.
$analyse_country_body = $analyse_country_body."
</body>
</html>
";

my $html_code = $analyse_country_head.$analyse_country_body;                                                                     #fusion du header et du body

open(my $html_file, '>', 'Rapport (par catégorie).html') or die "Impossible d'ouvrir le fichier HTML : $!";               #écriture du code .html dans le document final
print $html_file $html_code;
close $html_file;

print "Rapport .html créé. \n";