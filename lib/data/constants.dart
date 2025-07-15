const List<String> radarEnabledCountries = [
  'FI',
  'AX',
  'EE'
]; // Finland, Åland Islands, Estonia
const List<String> observationsEnabledCountries = ['FI', 'AX'];

// Finnish municipality codes
const Map<int, String> municipalities = {
  47: 'Enontekiö',
  890: 'Utsjoki',
  148: 'Inari',
  498: 'Muonio',
  273: 'Kolari',
  261: 'Kittilä',
  758: 'Sodankylä',
  742: 'Savukoski',
  583: 'Pelkosenniemi',
  732: 'Salla',
  854: 'Pello',
  976: 'Ylitornio',
  698: 'Rovaniemi',
  320: 'Kemijärvi',
  851: 'Tornio',
  845: 'Tervola',
  241: 'Keminmaa',
  240: 'Kemi',
  751: 'Simo',
  683: 'Ranua',
  614: 'Posio',
};

// ISO 3166-2 regions for Finland
const Map<String, Map<String, String>> regions = {
  'fi': {
    "FI-01": "Ahvenanmaan maakunta",
    "FI-02": "Etelä-Karjala",
    "FI-03": "Etelä-Pohjanmaa",
    "FI-04": "Etelä-Savo",
    "FI-05": "Kainuu",
    "FI-06": "Kanta-Häme",
    "FI-07": "Keski-Pohjanmaa",
    "FI-08": "Keski-Suomi",
    "FI-09": "Kymenlaakso",
    "FI-10": "Lappi",
    "FI-11": "Pirkanmaa",
    "FI-12": "Pohjanmaa",
    "FI-13": "Pohjois-Karjala",
    "FI-14": "Pohjois-Pohjanmaa",
    "FI-15": "Pohjois-Savo",
    "FI-16": "Päijät-Häme",
    "FI-17": "Satakunta",
    "FI-18": "Uusimaa",
    "FI-19": "Varsinais-Suomi"
  },
  'en': {
    "FI-01": "Åland",
    "FI-02": "South Karelia",
    "FI-03": "South Ostrobothnia",
    "FI-04": "South Savo",
    "FI-05": "Kainuu",
    "FI-06": "Kanta-Häme",
    "FI-07": "Central Ostrobothnia",
    "FI-08": "Central Finland",
    "FI-09": "Kymenlaakso",
    "FI-10": "Lapland",
    "FI-11": "Pirkanmaa",
    "FI-12": "Ostrobothnia",
    "FI-13": "North Karelia",
    "FI-14": "North Ostrobothnia",
    "FI-15": "North Savo",
    "FI-16": "Päijät-Häme",
    "FI-17": "Satakunta",
    "FI-18": "Uusimaa",
    "FI-19": "Southwest Finland"
  }
};
