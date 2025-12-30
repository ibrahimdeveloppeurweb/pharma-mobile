import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchPlacesService {
 final String accessKey = dotenv.env['AWS_ACCESS_KEY']!;
  final String secretKey = dotenv.env['AWS_SECRET_KEY']!;
  final String region = dotenv.env['AWS_REGION']!;
  final String indexName = dotenv.env['AWS_INDEX_NAME']!;

  // Base de données locale des sous-quartiers d'Abidjan
  // Base de données ultra-complète des sous-quartiers d'Abidjan
  static const Map<String, List<Map<String, dynamic>>> sousQuartiers = {
    "Cocody": [
      // Riviera
      {"nom": "Riviera Palmeraie", "lat": 5.3515, "lon": -3.9844},
      {"nom": "Riviera Golf", "lat": 5.3447, "lon": -3.9722},
      {"nom": "Riviera 2", "lat": 5.3489, "lon": -3.9889},
      {"nom": "Riviera 3", "lat": 5.3523, "lon": -3.9912},
      {"nom": "Riviera 4", "lat": 5.3556, "lon": -3.9978},
      {"nom": "Riviera Attoban", "lat": 5.3478, "lon": -3.9756},
      {"nom": "Riviera Faya", "lat": 5.3501, "lon": -3.9801},
      {"nom": "Riviera Bonoumin", "lat": 5.3534, "lon": -3.9823},
      {"nom": "Riviera M'Pouto", "lat": 5.3467, "lon": -3.9867},

      // Deux Plateaux
      {"nom": "Deux Plateaux", "lat": 5.3598, "lon": -4.0089},
      {"nom": "Deux Plateaux Vallon", "lat": 5.3612, "lon": -4.0123},
      {"nom": "Deux Plateaux 7ème Tranche", "lat": 5.3645, "lon": -4.0067},
      {"nom": "Deux Plateaux 8ème Tranche", "lat": 5.3678, "lon": -4.0034},
      {"nom": "Deux Plateaux Extension", "lat": 5.3634, "lon": -4.0156},
      {"nom": "Deux Plateaux Cité des Arts", "lat": 5.3589, "lon": -4.0134},

      // Angré
      {"nom": "Angré", "lat": 5.3797, "lon": -3.9886},
      {"nom": "Angré 7ème Tranche", "lat": 5.3845, "lon": -3.9923},
      {"nom": "Angré 8ème Tranche", "lat": 5.3889, "lon": -3.9956},
      {"nom": "Angré 9ème Tranche", "lat": 5.3923, "lon": -3.9989},
      {"nom": "Angré Château", "lat": 5.3756, "lon": -3.9812},
      {"nom": "Angré Nouveau CHU", "lat": 5.3812, "lon": -3.9845},
      {"nom": "Angré Djibi", "lat": 5.3867, "lon": -3.9878},
      {"nom": "Angré Stars", "lat": 5.3734, "lon": -3.9901},

      // Centre Cocody
      {"nom": "Cocody Centre", "lat": 5.3357, "lon": -4.0106},
      {"nom": "Cocody Danga", "lat": 5.3423, "lon": -4.0156},
      {"nom": "Cocody Ambassades", "lat": 5.3289, "lon": -4.0334},
      {"nom": "Cocody II Plateaux", "lat": 5.3567, "lon": -4.0045},
      {"nom": "Cocody 7ème Tranche", "lat": 5.3678, "lon": -4.0012},
      {"nom": "Cocody Blockhaus", "lat": 5.3712, "lon": -4.0089},
      {"nom": "Cocody Faya", "lat": 5.3645, "lon": -4.0167},
      {"nom": "Cocody Lycée Technique", "lat": 5.3534, "lon": -4.0234},
      {"nom": "Cocody Saint Jean", "lat": 5.3478, "lon": -4.0189},
      {"nom": "Cocody M'Pouto", "lat": 5.3401, "lon": -4.0267},
      {"nom": "Cocody Abatta", "lat": 5.3256, "lon": -4.0456},
      {"nom": "Cocody Bonoumin", "lat": 5.3512, "lon": -4.0389},
      {"nom": "Cocody II Plateaux 1", "lat": 5.3545, "lon": -4.0023},
      {"nom": "Cocody II Plateaux 2", "lat": 5.3578, "lon": -4.0078},
      {"nom": "Cocody Sideci", "lat": 5.3623, "lon": -4.0112},
      {"nom": "Cocody Akouédo", "lat": 5.3689, "lon": -4.0145},
      {"nom": "Cocody Anono", "lat": 5.3456, "lon": -4.0423},
      {"nom": "Cocody Caféier", "lat": 5.3501, "lon": -4.0456},
    ],

    "Yopougon": [
      // Secteur industriel
      {"nom": "Yopougon Niangon", "lat": 5.3392, "lon": -4.0892},
      {"nom": "Yopougon Niangon Nord", "lat": 5.3423, "lon": -4.0867},
      {"nom": "Yopougon Niangon Sud", "lat": 5.3367, "lon": -4.0923},
      {"nom": "Yopougon Sideci", "lat": 5.3249, "lon": -4.1058},
      {"nom": "Yopougon Ananeraie", "lat": 5.3141, "lon": -4.0978},
      {"nom": "Yopougon Maroc", "lat": 5.3312, "lon": -4.1123},
      {"nom": "Yopougon Selmer", "lat": 5.3178, "lon": -4.1189},
      {"nom": "Yopougon Port", "lat": 5.3267, "lon": -4.1256},

      // Quartiers résidentiels
      {"nom": "Yopougon Mossikro", "lat": 5.3089, "lon": -4.1067},
      {"nom": "Yopougon Attié", "lat": 5.3156, "lon": -4.0889},
      {"nom": "Yopougon SIDA", "lat": 5.3223, "lon": -4.0945},
      {"nom": "Yopougon Micao", "lat": 5.3345, "lon": -4.1012},
      {"nom": "Yopougon Sogefiha", "lat": 5.3412, "lon": -4.1145},
      {"nom": "Yopougon Nimbo", "lat": 5.3478, "lon": -4.1223},
      {"nom": "Yopougon Gesco", "lat": 5.3534, "lon": -4.1089},
      {"nom": "Yopougon Andokoi", "lat": 5.3289, "lon": -4.0823},
      {"nom": "Yopougon Koweït", "lat": 5.3367, "lon": -4.0956},
      {"nom": "Yopougon Siporex", "lat": 5.3423, "lon": -4.1034},
      {"nom": "Yopougon Belleville", "lat": 5.3101, "lon": -4.1145},
      {"nom": "Yopougon Toits Rouges", "lat": 5.3189, "lon": -4.1212},
      {"nom": "Yopougon Sagbé", "lat": 5.3456, "lon": -4.0867},
      {"nom": "Yopougon Banco", "lat": 5.3523, "lon": -4.0934},

      // Nouveaux quartiers
      {"nom": "Yopougon Millionnaire", "lat": 5.3334, "lon": -4.1178},
      {"nom": "Yopougon Toit Rouge", "lat": 5.3201, "lon": -4.1234},
      {"nom": "Yopougon Terminal", "lat": 5.3278, "lon": -4.1089},
      {"nom": "Yopougon Yaosséhi", "lat": 5.3445, "lon": -4.1167},
      {"nom": "Yopougon Wassakara", "lat": 5.3512, "lon": -4.1234},
      {"nom": "Yopougon Nouveau Quartier", "lat": 5.3123, "lon": -4.0934},
      {"nom": "Yopougon Bel Air", "lat": 5.3234, "lon": -4.1001},
      {"nom": "Yopougon Zone Industrielle", "lat": 5.3298, "lon": -4.1289},
      {"nom": "Yopougon Ficgayo", "lat": 5.3367, "lon": -4.1198},
      {"nom": "Yopougon Kennedy", "lat": 5.3489, "lon": -4.1156},
      {"nom": "Yopougon Azito", "lat": 5.3556, "lon": -4.1023},
    ],

    "Abobo": [
      // Zone centrale
      {"nom": "Abobo Gare", "lat": 5.4235, "lon": -4.0198},
      {"nom": "Abobo Baoulé", "lat": 5.4198, "lon": -4.0089},
      {"nom": "Abobo PK18", "lat": 5.4312, "lon": -4.0156},
      {"nom": "Abobo Avocatier", "lat": 5.4089, "lon": -4.0267},
      {"nom": "Abobo Sagbé", "lat": 5.4156, "lon": -4.0334},
      {"nom": "Abobo Té", "lat": 5.4267, "lon": -4.0423},

      // Zone nord
      {"nom": "Abobo Derrière Rail", "lat": 5.4345, "lon": -4.0289},
      {"nom": "Abobo N'Dotré", "lat": 5.4423, "lon": -4.0367},
      {"nom": "Abobo Belleville", "lat": 5.4178, "lon": -4.0445},
      {"nom": "Abobo Anador", "lat": 5.4389, "lon": -4.0234},
      {"nom": "Abobo Anonkoua Kouté", "lat": 5.4467, "lon": -4.0312},
      {"nom": "Abobo Banco 2", "lat": 5.4289, "lon": -4.0512},
      {"nom": "Abobo Plaque", "lat": 5.4367, "lon": -4.0489},
      {"nom": "Abobo Kennedy", "lat": 5.4123, "lon": -4.0156},
      {"nom": "Abobo Clouetcha", "lat": 5.4501, "lon": -4.0267},
      {"nom": "Abobo Agbekoi", "lat": 5.4445, "lon": -4.0445},

      // Extension Abobo
      {"nom": "Abobo Dokui", "lat": 5.4534, "lon": -4.0389},
      {"nom": "Abobo Mossikro", "lat": 5.4267, "lon": -4.0356},
      {"nom": "Abobo Santé", "lat": 5.4312, "lon": -4.0534},
      {"nom": "Abobo Extension", "lat": 5.4389, "lon": -4.0578},
      {"nom": "Abobo Abatta", "lat": 5.4456, "lon": -4.0523},
      {"nom": "Abobo M'Badon", "lat": 5.4223, "lon": -4.0401},
      {"nom": "Abobo Biabou", "lat": 5.4156, "lon": -4.0512},
      {"nom": "Abobo Houphouët", "lat": 5.4334, "lon": -4.0267},
      {"nom": "Abobo Sokoura", "lat": 5.4278, "lon": -4.0589},
      {"nom": "Abobo Abobo Doumé", "lat": 5.4412, "lon": -4.0612},
      {"nom": "Abobo Brasseries", "lat": 5.4189, "lon": -4.0378},
      {"nom": "Abobo CHU", "lat": 5.4245, "lon": -4.0445},
    ],

    "Adjamé": [
      {"nom": "Adjamé 220 Logements", "lat": 5.3512, "lon": -4.0267},
      {"nom": "Adjamé Liberté", "lat": 5.3489, "lon": -4.0198},
      {"nom": "Adjamé Williamsville", "lat": 5.3567, "lon": -4.0334},
      {"nom": "Adjamé Roxy", "lat": 5.3445, "lon": -4.0289},
      {"nom": "Adjamé Bracodi", "lat": 5.3423, "lon": -4.0356},
      {"nom": "Adjamé Saint Michel", "lat": 5.3534, "lon": -4.0223},
      {"nom": "Adjamé Genevieve", "lat": 5.3478, "lon": -4.0312},
      {"nom": "Adjamé Sokoura", "lat": 5.3401, "lon": -4.0245},
      {"nom": "Adjamé Mairie", "lat": 5.3556, "lon": -4.0289},
      {"nom": "Adjamé Habitat", "lat": 5.3612, "lon": -4.0367},
      {"nom": "Adjamé Nord", "lat": 5.3589, "lon": -4.0301},
      {"nom": "Adjamé Sud", "lat": 5.3467, "lon": -4.0278},
      {"nom": "Adjamé Village", "lat": 5.3523, "lon": -4.0389},
      {"nom": "Adjamé Extension", "lat": 5.3634, "lon": -4.0412},
      {"nom": "Adjamé Paillet", "lat": 5.3578, "lon": -4.0256},
      {"nom": "Adjamé Indénié", "lat": 5.3445, "lon": -4.0334},
      {"nom": "Adjamé Dallas", "lat": 5.3501, "lon": -4.0423},
    ],

    "Plateau": [
      {"nom": "Plateau Dokui", "lat": 5.3289, "lon": -4.0198},
      {"nom": "Plateau Centre", "lat": 5.3245, "lon": -4.0267},
      {"nom": "Plateau Ministères", "lat": 5.3223, "lon": -4.0334},
      {"nom": "Plateau Cathédrale", "lat": 5.3267, "lon": -4.0223},
      {"nom": "Plateau Pharmacie", "lat": 5.3312, "lon": -4.0289},
      {"nom": "Plateau Gare Lagune", "lat": 5.3178, "lon": -4.0312},
      {"nom": "Plateau Avocatier", "lat": 5.3334, "lon": -4.0245},
      {"nom": "Plateau Caistab", "lat": 5.3201, "lon": -4.0245},
      {"nom": "Plateau Cité Administrative", "lat": 5.3256, "lon": -4.0289},
      {"nom": "Plateau Banques", "lat": 5.3278, "lon": -4.0256},
      {"nom": "Plateau Hôtel Ivoire", "lat": 5.3234, "lon": -4.0378},
      {"nom": "Plateau Vallons", "lat": 5.3312, "lon": -4.0356},
    ],

    "Marcory": [
      {"nom": "Marcory Zone 4", "lat": 5.3067, "lon": -4.0089},
      {"nom": "Marcory Zone 4A", "lat": 5.3089, "lon": -4.0067},
      {"nom": "Marcory Zone 4B", "lat": 5.3045, "lon": -4.0112},
      {"nom": "Marcory Zone 4C", "lat": 5.3023, "lon": -4.0134},
      {"nom": "Marcory Résidentiel", "lat": 5.3123, "lon": -3.9978},
      {"nom": "Marcory Biétry", "lat": 5.3156, "lon": -4.0023},
      {"nom": "Marcory Anoumambo", "lat": 5.3089, "lon": -4.0156},
      {"nom": "Marcory SICOGI", "lat": 5.3012, "lon": -4.0123},
      {"nom": "Marcory Remblais", "lat": 5.2989, "lon": -4.0189},
      {"nom": "Marcory Zone 3", "lat": 5.3045, "lon": -4.0067},
      {"nom": "Marcory Zone 2", "lat": 5.3101, "lon": -4.0012},
      {"nom": "Marcory Zone 1", "lat": 5.3134, "lon": -3.9956},
      {"nom": "Marcory Camp Commando", "lat": 5.2967, "lon": -4.0223},
      {"nom": "Marcory Bel Air", "lat": 5.3178, "lon": -4.0045},
      {"nom": "Marcory Village", "lat": 5.3145, "lon": -4.0089},
      {"nom": "Marcory Maroc", "lat": 5.3001, "lon": -4.0156},
    ],

    "Treichville": [
      {"nom": "Treichville Centre", "lat": 5.3089, "lon": -4.0156},
      {"nom": "Treichville Arras 1", "lat": 5.3123, "lon": -4.0089},
      {"nom": "Treichville Arras 2", "lat": 5.3145, "lon": -4.0123},
      {"nom": "Treichville Belleville", "lat": 5.3067, "lon": -4.0223},
      {"nom": "Treichville Abidjan Gare", "lat": 5.3034, "lon": -4.0189},
      {"nom": "Treichville Biafra", "lat": 5.3101, "lon": -4.0267},
      {"nom": "Treichville Zone 4", "lat": 5.3156, "lon": -4.0234},
      {"nom": "Treichville Zone 3", "lat": 5.3112, "lon": -4.0198},
      {"nom": "Treichville Zone 2", "lat": 5.3078, "lon": -4.0134},
      {"nom": "Treichville Zone 1", "lat": 5.3134, "lon": -4.0067},
      {"nom": "Treichville Vridi", "lat": 5.3023, "lon": -4.0256},
      {"nom": "Treichville Ancien Bassam", "lat": 5.2989, "lon": -4.0289},
      {"nom": "Treichville Marseille", "lat": 5.3167, "lon": -4.0178},
    ],

    "Koumassi": [
      {"nom": "Koumassi Remblais", "lat": 5.3156, "lon": -3.9667},
      {"nom": "Koumassi Grand Carrefour", "lat": 5.3189, "lon": -3.9578},
      {"nom": "Koumassi Grand Campement", "lat": 5.3223, "lon": -3.9723},
      {"nom": "Koumassi Sicogi", "lat": 5.3267, "lon": -3.9812},
      {"nom": "Koumassi Nouveau Quartier", "lat": 5.3123, "lon": -3.9534},
      {"nom": "Koumassi Zone Industrielle", "lat": 5.3089, "lon": -3.9601},
      {"nom": "Koumassi Résidentiel", "lat": 5.3201, "lon": -3.9645},
      {"nom": "Koumassi Habitat", "lat": 5.3245, "lon": -3.9689},
      {"nom": "Koumassi Anono", "lat": 5.3178, "lon": -3.9756},
      {"nom": "Koumassi Village", "lat": 5.3134, "lon": -3.9812},
      {"nom": "Koumassi Extension", "lat": 5.3289, "lon": -3.9623},
      {"nom": "Koumassi Blokosso", "lat": 5.3312, "lon": -3.9567},
      {"nom": "Koumassi Banco", "lat": 5.3067, "lon": -3.9712},
    ],

    "Port-Bouët": [
      {"nom": "Port-Bouët Gonzagueville", "lat": 5.2678, "lon": -3.9456},
      {"nom": "Port-Bouët Vridi", "lat": 5.2456, "lon": -3.9789},
      {"nom": "Port-Bouët Aéroport", "lat": 5.2534, "lon": -3.9267},
      {"nom": "Port-Bouët Petit Bassam", "lat": 5.2612, "lon": -3.9534},
      {"nom": "Port-Bouët Zone 3", "lat": 5.2589, "lon": -3.9612},
      {"nom": "Port-Bouët Zone 4A", "lat": 5.2723, "lon": -3.9389},
      {"nom": "Port-Bouët Zone 4B", "lat": 5.2756, "lon": -3.9523},
      {"nom": "Port-Bouët Zone 4C", "lat": 5.2689, "lon": -3.9601},
      {"nom": "Port-Bouët Champroux", "lat": 5.2645, "lon": -3.9723},
      {"nom": "Port-Bouët Wharf", "lat": 5.2501, "lon": -3.9834},
      {"nom": "Port-Bouët FHB", "lat": 5.2567, "lon": -3.9312},
      {"nom": "Port-Bouët Cite Aéroport", "lat": 5.2512, "lon": -3.9223},
      {"nom": "Port-Bouët Village", "lat": 5.2634, "lon": -3.9489},
      {"nom": "Port-Bouët Phare", "lat": 5.2423, "lon": -3.9856},
      {"nom": "Port-Bouët Camp Mili", "lat": 5.2778, "lon": -3.9445},
    ],

    "Attécoubé": [
      {"nom": "Attécoubé Santé", "lat": 5.3312, "lon": -4.0445},
      {"nom": "Attécoubé Locodjro", "lat": 5.3345, "lon": -4.0512},
      {"nom": "Attécoubé Terminus 41", "lat": 5.3278, "lon": -4.0578},
      {"nom": "Attécoubé Anguédédou", "lat": 5.3389, "lon": -4.0389},
      {"nom": "Attécoubé Mairie", "lat": 5.3423, "lon": -4.0467},
      {"nom": "Attécoubé Gendarmerie", "lat": 5.3367, "lon": -4.0534},
      {"nom": "Attécoubé Djékanou", "lat": 5.3456, "lon": -4.0423},
      {"nom": "Attécoubé Village", "lat": 5.3334, "lon": -4.0489},
      {"nom": "Attécoubé Extension", "lat": 5.3489, "lon": -4.0556},
      {"nom": "Attécoubé Dépôt", "lat": 5.3267, "lon": -4.0612},
      {"nom": "Attécoubé Akouédo", "lat": 5.3401, "lon": -4.0601},
    ],

    "Bingerville": [
      {"nom": "Bingerville Centre", "lat": 5.3567, "lon": -3.8923},
      {"nom": "Bingerville M'Batto", "lat": 5.3623, "lon": -3.8856},
      {"nom": "Bingerville Akouédo", "lat": 5.3689, "lon": -3.8789},
      {"nom": "Bingerville New Town", "lat": 5.3534, "lon": -3.9012},
      {"nom": "Bingerville Village", "lat": 5.3601, "lon": -3.8967},
      {"nom": "Bingerville Ancien Orphelinat", "lat": 5.3645, "lon": -3.9023},
      {"nom": "Bingerville Extension", "lat": 5.3712, "lon": -3.8823},
      {"nom": "Bingerville Administratif", "lat": 5.3578, "lon": -3.8889},
      {"nom": "Bingerville Jardin Botanique", "lat": 5.3656, "lon": -3.8945},
    ],

    "Songon": [
      {"nom": "Songon Agnibilékrou", "lat": 5.2912, "lon": -4.2456},
      {"nom": "Songon Village", "lat": 5.2845, "lon": -4.2389},
      {"nom": "Songon M'Bratté", "lat": 5.2978, "lon": -4.2523},
      {"nom": "Songon Dagbé", "lat": 5.3045, "lon": -4.2612},
      {"nom": "Songon Akouédo", "lat": 5.2878, "lon": -4.2534},
      {"nom": "Songon Extension", "lat": 5.3012, "lon": -4.2678},
      {"nom": "Songon Té", "lat": 5.2789, "lon": -4.2445},
    ],

    "Anyama": [
      {"nom": "Anyama Agban", "lat": 5.4956, "lon": -4.0523},
      {"nom": "Anyama Ahouabo", "lat": 5.5023, "lon": -4.0456},
      {"nom": "Anyama Village", "lat": 5.4889, "lon": -4.0612},
      {"nom": "Anyama Ebimpé", "lat": 5.5089, "lon": -4.0589},
      {"nom": "Anyama Anono", "lat": 5.4823, "lon": -4.0678},
      {"nom": "Anyama Extension", "lat": 5.5134, "lon": -4.0512},
      {"nom": "Anyama Nouveau Quartier", "lat": 5.4912, "lon": -4.0545},
      {"nom": "Anyama Habitat", "lat": 5.5056, "lon": -4.0623},
      {"nom": "Anyama CHR", "lat": 5.4978, "lon": -4.0578},
    ],
  };

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    List<Map<String, dynamic>> allResults = [];

    // 1. Rechercher dans AWS (villes, communes, grandes zones)
    var awsResults = await _searchWithAWS(query);
    allResults.addAll(awsResults);

    // 2. Rechercher dans la base locale des sous-quartiers
    var localResults = _searchLocalSousQuartiers(query);
    allResults.addAll(localResults);

    // 3. Dédupliquer et trier par pertinence
    return _deduplicateAndSort(allResults, query);
  }

  Future<List<Map<String, dynamic>>> _searchWithAWS(String query) async {
    final host = "places.geo.$region.amazonaws.com";
    final path = "/places/v0/indexes/$indexName/search/text";

    final body = json.encode({
      "Text": query,
      "MaxResults": 15,
      "FilterCountries": ["CIV"],
      "Language": "fr"
    });

    final now = DateTime.now().toUtc();
    final amzDate = now.toIso8601String().replaceAll(RegExp(r'[:-]|\.\d+'), '').replaceAll('Z', '') + "Z";
    final dateStamp = amzDate.substring(0, 8);
    final contentType = "application/json; charset=utf-8";

    final canonicalRequest = StringBuffer()
      ..writeln("POST")
      ..writeln(path)
      ..writeln("")
      ..writeln("content-type:$contentType")
      ..writeln("host:$host")
      ..writeln("x-amz-date:$amzDate")
      ..writeln("")
      ..writeln("content-type;host;x-amz-date")
      ..write(sha256.convert(utf8.encode(body)).toString());

    final credentialScope = "$dateStamp/$region/geo/aws4_request";
    final stringToSign = StringBuffer()
      ..writeln("AWS4-HMAC-SHA256")
      ..writeln(amzDate)
      ..writeln(credentialScope)
      ..write(sha256.convert(utf8.encode(canonicalRequest.toString())).toString());

    Uint8List hmacSha256(Uint8List key, String message) {
      final hmac = Hmac(sha256, key);
      return Uint8List.fromList(hmac.convert(utf8.encode(message)).bytes);
    }

    var kDate = hmacSha256(Uint8List.fromList(utf8.encode("AWS4$secretKey")), dateStamp);
    var kRegion = hmacSha256(kDate, region);
    var kService = hmacSha256(kRegion, "geo");
    var kSigning = hmacSha256(kService, "aws4_request");
    var signatureBytes = hmacSha256(kSigning, stringToSign.toString());

    final signature = signatureBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final authHeader = "AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=content-type;host;x-amz-date, Signature=$signature";

    try {
      final response = await http.post(
        Uri.https(host, path),
        headers: {
          "Content-Type": contentType,
          "X-Amz-Date": amzDate,
          "Authorization": authHeader,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data["Results"] as List;
        return results.map((r) => {
          "label": r["Place"]["Label"],
          "lat": r["Place"]["Geometry"]["Point"][1],
          "lon": r["Place"]["Geometry"]["Point"][0],
          "source": "aws"
        }).toList();
      }
    } catch (e) {
      print("AWS Exception: $e");
    }

    return [];
  }

  List<Map<String, dynamic>> _searchLocalSousQuartiers(String query) {
    final queryLower = query.toLowerCase().trim();
    List<Map<String, dynamic>> results = [];

    sousQuartiers.forEach((commune, quartiers) {
      for (var quartier in quartiers) {
        final nomQuartier = quartier["nom"] as String;

        // Recherche flexible (contient le texte)
        if (nomQuartier.toLowerCase().contains(queryLower) ||
            commune.toLowerCase().contains(queryLower)) {
          results.add({
            "label": "$nomQuartier, $commune, Abidjan, Côte d'Ivoire",
            "lat": quartier["lat"],
            "lon": quartier["lon"],
            "source": "local"
          });
        }
      }
    });

    return results;
  }

  List<Map<String, dynamic>> _deduplicateAndSort(
      List<Map<String, dynamic>> results,
      String query
      ) {
    // Supprimer les doublons basés sur les coordonnées proches
    final uniqueResults = <Map<String, dynamic>>[];

    for (var result in results) {
      bool isDuplicate = uniqueResults.any((existing) {
        double latDiff = (existing["lat"] - result["lat"]).abs();
        double lonDiff = (existing["lon"] - result["lon"]).abs();
        return latDiff < 0.001 && lonDiff < 0.001; // ~100m de précision
      });

      if (!isDuplicate) {
        uniqueResults.add(result);
      }
    }

    // Trier par pertinence (commence par la requête = plus pertinent)
    uniqueResults.sort((a, b) {
      final aLabel = (a["label"] as String).toLowerCase();
      final bLabel = (b["label"] as String).toLowerCase();
      final queryLower = query.toLowerCase();

      bool aStarts = aLabel.startsWith(queryLower);
      bool bStarts = bLabel.startsWith(queryLower);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return aLabel.compareTo(bLabel);
    });

    return uniqueResults.take(10).toList();
  }
}