#! /usr/bin/perl
#=====================================================
# Script : Sentiment_Analysis_project.pl
# Auteur : Loïc Laridant <loic.laridant@student.uclouvain.be>
# Date   : 17/06/2023
# Numérotation projet : 2/3
#=====================================================
# Usage  : perl analyse_global.pl [Chemin jusque la qase de données textuelles] [Chemin jusqu'au lexique des émotions]
#=====================================================
# Exigences : 
#   - Installation du module GD::Graph::bars
#   - Accès aux documents (devant se trouver dans le même répertoire) :
#       - Lexiques_emotions//emotions_EN.txt
#       - Lexiques_emotions//emotions_FR.txt
#       - style.css
#=====================================================
# Informations : Ce script secondaire va nous permettre d'analyser les émotions évoquées dans l'ensemble des lignes mentionnées dans un document source.
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
#CREATION DES TABLES DE HACHAGES NECESSAIRES A' L'ANALYSE

my %emotion_global;                                                                                                              #création d'une table de hachage reprenant les scores globaux de chaque sentiment étudié
$emotion_global{'joie'}=0;
$emotion_global{'surprise'}=0;
$emotion_global{'colere'}=0;
$emotion_global{'degout'}=0;
$emotion_global{'peur'}=0;
$emotion_global{'tristesse'}=0;
$emotion_global{'positif'}=0;
$emotion_global{'négatif'}=0;
$emotion_global{'count'}=0;

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
#ANALYSE DU CONTENU DU DOCUMENT COMPRENANT LES DONNEES TEXTUELLE

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
    my @word_tweet_list = split (" ",$line);
    my %emotion_temp;                                                                                                            #création et réinitialisation du dictionnaire temporaire (pour chaque ligne) dans lequel le script sauvegardera les scores calculés pour les différents termes d'une ligne
    $emotion_temp{'joie'}=0;
    $emotion_temp{'surprise'}=0;
    $emotion_temp{'colere'}=0;
    $emotion_temp{'degout'}=0;
    $emotion_temp{'peur'}=0;
    $emotion_temp{'tristesse'}=0;
    $emotion_temp{'positif'}=0;
    $emotion_temp{'negatif'}=0;
    $emotion_temp{'count'}=0;
    foreach my $word_tweet (@word_tweet_list){                                                                                   #itération par terme 
        if (exists $word_emotion{$word_tweet}){                                                                                  #vérification si le terme itéré apparaît dans le dictionnaire des émotions
            $emotion_temp{'joie'}+=$word_emotion{$word_tweet}[0];
            $emotion_temp{'surprise'}+=$word_emotion{$word_tweet}[1];
            $emotion_temp{'colere'}+=$word_emotion{$word_tweet}[2];
            $emotion_temp{'degout'}+=$word_emotion{$word_tweet}[3];
            $emotion_temp{'peur'}+=$word_emotion{$word_tweet}[4];
            $emotion_temp{'tristesse'}+=$word_emotion{$word_tweet}[5];
            $emotion_temp{'positif'}+=$word_emotion{$word_tweet}[6];
            $emotion_temp{'negatif'}+=$word_emotion{$word_tweet}[7];
            $emotion_temp{'count'}+=1;                                                                                           #compteur qui nous permettra d'effectuer la moyenne générale par ligne
        }
}
        if ($emotion_temp{'count'} == 0){                                                                                        #dans le cas où aucune ligne n'aurait été analysée, l'on donne 1 comme valeur au compteur
            $emotion_temp{'count'}+=1;                                                                                           #(afin d'éviter une division par 0 - une division par 1 n'ayant pas d'effet)
        }
         if ($emotion_temp{'count'} != 1){
             if (sprintf("%.2f",($emotion_temp{'joie'}/$emotion_temp{'count'}))>$max_joy){                                       #pour chaque émotion, l'on va vérifier si le score de la ligne est supérieur au maximum enregistré
                $max_joy=sprintf("%.2f",($emotion_temp{'joie'}/$emotion_temp{'count'}));                                         #si oui, les variables de maximum et celle enregistrant la ligne seront mises à jour (sinon ça passe)
                $text_max_joy = $line;                                                                                           #utilisation de la fonction sprintf("%.2f",... pour créer des nombres arrondis à 2 décimales
             }
             if (sprintf("%.2f",($emotion_temp{'surprise'}/$emotion_temp{'count'}))>$max_surprise){
                $max_surprise=sprintf("%.2f",($emotion_temp{'surprise'}/$emotion_temp{'count'}));
                $text_max_surprise = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'colere'}/$emotion_temp{'count'}))>$max_anger){
                $max_anger=sprintf("%.2f",($emotion_temp{'colere'}/$emotion_temp{'count'}));
                $text_max_anger = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'degout'}/$emotion_temp{'count'}))>$max_disgust){
                $max_disgust=sprintf("%.2f",($emotion_temp{'degout'}/$emotion_temp{'count'}));
                $text_max_disgust = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'peur'}/$emotion_temp{'count'}))>$max_fear){
                $max_fear=sprintf("%.2f",($emotion_temp{'peur'}/$emotion_temp{'count'}));
                $text_max_fear = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'tristesse'}/$emotion_temp{'count'}))>$max_sadness){
                $max_sadness=sprintf("%.2f",($emotion_temp{'tristesse'}/$emotion_temp{'count'}));
                $text_max_sadness = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'positif'}/$emotion_temp{'count'}))>$max_pos){
                $max_pos=sprintf("%.2f",($emotion_temp{'positif'}/$emotion_temp{'count'}));
                $text_max_pos = $line;
             }
             if (sprintf("%.2f",($emotion_temp{'negatif'}/$emotion_temp{'count'}))>$max_neg){
                $max_neg=sprintf("%.2f",($emotion_temp{'negatif'}/$emotion_temp{'count'}));
                $text_max_neg = $line;
             }
         }
         $emotion_global{'joie'}+=($emotion_temp{'joie'}/$emotion_temp{'count'});                                                #après l'analyse de tous les termes d'une ligne, de la mise à jour des variables de maximum (cf. dernier commentaire)
         $emotion_global{'surprise'}+=($emotion_temp{'surprise'}/$emotion_temp{'count'});                                        #le programme met à jour le dictionnaire global (%emotion_global)  en effectuant une moyenne générale des scores par ligne
         $emotion_global{'colere'}+=($emotion_temp{'colere'}/$emotion_temp{'count'});                                            #à l'aide du compteur ($emotion_temp{'count'})
         $emotion_global{'degout'}+=($emotion_temp{'degout'}/$emotion_temp{'count'});                                                  
         $emotion_global{'peur'}+=($emotion_temp{'peur'}/$emotion_temp{'count'});
         $emotion_global{'tristesse'}+=($emotion_temp{'tristesse'}/$emotion_temp{'count'});
         $emotion_global{'positif'}+=($emotion_temp{'positif'}/$emotion_temp{'count'});
         $emotion_global{'negatif'}+=($emotion_temp{'negatif'}/$emotion_temp{'count'}); 
         $emotion_global{'count'}+= 1;                                                                                           #création d'un compteur (représentant le nombre de lignes analysées) nécessaire au calcul ultérieur de la moyenne globale
         }
    if ($emotion_global{'count'} == 0){                                                                                          #dans le cas où aucune ligne n'aurait été analysée, l'on donne 1 comme valeur au compteur
        $emotion_global{'count'}+=1;                                                                                             #(afin d'éviter une division par 0 - une division par 1 n'ayant pas d'effet)
    }

print "Analyse du corpus effectuée.\n";
###############################################################################################################
#CREATION DU GRAPHIQUE PNG - SENTIMENTS EN GENERAL

print "Création des représentations graphiques (.png).\n";

my $data = GD::Graph::Data->new([                                                                                                #création des listes nécessaires à la création du graphique représentant le score de chaque émotion
    ['joy','surprise','anger','disgust','fear','sadness'],                                                                       #initialisation de l'objet 'graph' et des valeurs (calcul de la moyenne par sentiment à l'aide du compteur $emotion_global{'count}')
    [($emotion_global{'joie'} / $emotion_global{'count'}),($emotion_global{'surprise'} / $emotion_global{'count'}),($emotion_global{'colere'} / $emotion_global{'count'}),($emotion_global{'degout'} / $emotion_global{'count'}),($emotion_global{'peur'} / $emotion_global{'count'}),($emotion_global{'tristesse'} / $emotion_global{'count'})]
    ]);

my $graph = GD::Graph::bars->new(700, 500);                                                                                      #création de la représentation (format, labels, titre, maximum, ...)
    $graph->set(
        x_label    => 'Sentiment',
        x_label_font_size => 50,
        y_label    => 'Pourcentage moyen par ligne',
        y_max_value => 20,
        title      => "Graphique général"
    );

    open my $png1, '>', "Graphiques\\graphe_sentiments_general.png";                                                             #impression du graphique (sur base des listes de données mentionnées) dans un document au format.png
    binmode $png1;
    print $png1 $graph->plot($data)->png;
    close $png1;

###############################################################################################################
#CREATION DU GRAPHIQUE PNG - POSITIF ET NEGATIF

my $dataB = GD::Graph::Data->new([                                                                                               #initialisation de l'objet 'graph'
    ['positive','negative'],                                                                                                     #création des listes nécessaires à la création du graphique représentant le score positif et négatif
    [($emotion_global{'positif'} / $emotion_global{'count'}),($emotion_global{'negatif'} / $emotion_global{'count'})]
    ]);

my $graphB = GD::Graph::bars->new(700, 500);                                                                                     #création de la représentation (format, labels, titre, maximum, ...)
    $graphB->set(
        x_label    => 'Sentiment',
        x_label_font_size => 50,
        y_label    => 'Pourcentage moyen par ligne',
        y_max_value => 20,
        title      => "Comparaison des sentiments positifs et négatifs"
    );

    open my $png2, '>', "Graphiques\\graphe_positif_negatif.png";                                                                #impression du graphique dans un document au format.png
    binmode $png2;
    print $png2 $graphB->plot($dataB)->png;
    close $png2;

###############################################################################################################
#CREATION D'UN RAPPORT EN HTML - COMPOSITION DE L'ANALYSE

 # Création de la structure du document .html (header & balise script) - Intégration des données de l'analyse dans des graphiques proposées par Google Chart.
 # Mise en place d'un graphique représentant le score de l'ensemble des émotions. 
 # Intégration d'un tableau reprenant les lignes ayant eu le score le plus élevé pour chaque émotion. 
print "Création du rapport .html. \n";                                                                                          

my $analyse_content = "
<html>
  <head>
    <link rel='stylesheet' href='style.css'>
    <script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>
    <script type='text/javascript'>
      google.charts.load('current', {'packages':['bar']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Sentiment', 'Pourcentage moyen par ligne'],
          ['Joie', ($emotion_global{'joie'}/$emotion_global{'count'})],
          ['Surprise', ($emotion_global{'surprise'}/$emotion_global{'count'})],
          ['Colère', ($emotion_global{'colere'}/$emotion_global{'count'})],
          ['Dégoût', ($emotion_global{'degout'}/$emotion_global{'count'})],
          ['Peur', ($emotion_global{'peur'}/$emotion_global{'count'})],
          ['Tristesse', ($emotion_global{'tristesse'}/$emotion_global{'count'})],
          ['Positif', ($emotion_global{'positif'}/$emotion_global{'count'})],
          ['Negatif', ($emotion_global{'negatif'}/$emotion_global{'count'})]
        ]);

        var options = {
          chart: {
            title: 'Analyse des sentiments',
            subtitle: 'Pour les lignes comprenant le terme #MeToo',
          },
          bars: 'horizontal' 
        };

        var chart = new google.charts.Bar(document.getElementById('barchart_material'));

        chart.draw(data, google.charts.Bar.convertOptions(options));
      }
    </script>
    </script>
    <body>
    <h2>Rapport d'analyse des sentiments d'un corpus de données textuelles (ligne par ligne)</h2>
    <p>
    Ce rapport a été généré à l'aide du programme codé en perl accessible sur <a href='https://github.com/Llrdnt/projet_perl'>ce répositoire</a>.
    L'objectif de ce projet est d'effectuer une analyse des sentiments des tweets publiés entre janvier 2016 et novembre 2022 comprenant le '#MeToo'. 

    L'idée est de mettre en évidence les sentiments évoqués par les utilisateurs lorsqu'ils mentionnent le #MeToo. Cette analyse est basée sur un lexique de 1286 mots.
    Cette base de données créée par Gobin, P., Camblats, A. M., Faurous, W., & Mathey, S. est accessible via <a href='http://www.lexique.org/?page_id=492'>ce lien</a>.

    Ce rapport présentera :
    <ul>
        <li> Une analyse des sentiments évoqués</li>
        <li> Une présentation des lignes (tweets) ayant le score le plus élevé pour chaque émotion </li>
    </ul>
    </p>
   <div id='barchart_material' class = 'graph'></div>
    <hr>
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
</body>
</html>
";
# Fermeture de la balise <html> pour conclure le document.

open(my $html_file, '>', 'Rapport général.html') or die "Impossible d'ouvrir le fichier HTML : $!";
print $html_file $analyse_content;                                                                                               #écriture du code .html dans le document final
close $html_file;

print "Rapport .html créé. \n";