import '../../core/helpers/format_helper.dart';

/// A make customers can pick, with the Arabic name they may search by.
class CarMake {
  final String name;
  final String ar;
  final List<String> models;

  const CarMake(this.name, this.ar, this.models);
}

/// Makes and models common across Egypt and the Gulf, the most common first.
/// Anything missing is typed in by the customer, so this list only has to
/// cover most cars.
class CarCatalog {
  CarCatalog._();

  static const makes = <CarMake>[
    CarMake('Hyundai', 'هيونداي', ['Elantra', 'Accent', 'Verna', 'Sonata', 'Azera', 'Tucson', 'Creta', 'Kona', 'Santa Fe', 'Palisade', 'Staria', 'H-1', 'i10', 'i20', 'Bayon']),
    CarMake('Toyota', 'تويوتا', ['Corolla', 'Yaris', 'Belta', 'Camry', 'Avalon', 'Raize', 'C-HR', 'RAV4', 'Rush', 'Highlander', 'Fortuner', 'Prado', 'Land Cruiser', 'Sequoia', 'FJ Cruiser', 'Hilux', 'Innova', 'Hiace', 'Granvia']),
    CarMake('Kia', 'كيا', ['Cerato', 'K5', 'K8', 'Rio', 'Pegas', 'Picanto', 'Soluto', 'Sportage', 'Seltos', 'Sonet', 'Sorento', 'Telluride', 'Carnival']),
    CarMake('Nissan', 'نيسان', ['Sunny', 'Sentra', 'Altima', 'Maxima', 'Kicks', 'Juke', 'Qashqai', 'X-Trail', 'Pathfinder', 'X-Terra', 'Patrol', 'Navara', 'Urvan']),
    CarMake('Chevrolet', 'شيفروليه', ['Optra', 'Aveo', 'Lanos', 'Cruze', 'Spark', 'Groove', 'Malibu', 'Captiva', 'Blazer', 'Traverse', 'Tahoe', 'Suburban', 'Silverado', 'Camaro']),
    CarMake('Renault', 'رينو', ['Logan', 'Sandero', 'Stepway', 'Duster', 'Clio', 'Megane', 'Fluence', 'Kadjar', 'Austral']),
    CarMake('Peugeot', 'بيجو', ['301', '208', '308', '508', '2008', '3008', '5008']),
    CarMake('MG', 'إم جي', ['MG 5', 'MG 6', 'MG 4', 'ZS', 'HS', 'RX5', 'One']),
    CarMake('Mitsubishi', 'ميتسوبيشي', ['Lancer', 'Attrage', 'Mirage', 'Xpander', 'ASX', 'Eclipse Cross', 'Outlander', 'Montero Sport', 'Pajero', 'L200']),
    CarMake('Suzuki', 'سوزوكي', ['Swift', 'Dzire', 'Alto', 'Celerio', 'S-Presso', 'Ciaz', 'Ertiga', 'Vitara']),
    CarMake('Skoda', 'سكودا', ['Octavia', 'Fabia', 'Scala', 'Superb', 'Kamiq', 'Karoq', 'Kodiaq']),
    CarMake('Chery', 'شيري', ['Tiggo 3', 'Tiggo 4', 'Tiggo 7', 'Tiggo 8', 'Arrizo 5', 'Arrizo 6']),
    CarMake('BYD', 'بي واي دي', ['F3', 'Qin Plus', 'Song Plus', 'Atto 3', 'Dolphin', 'Seal']),
    CarMake('Fiat', 'فيات', ['Tipo', '500', '500X', 'Shahin', '128', 'Uno']),
    CarMake('Volkswagen', 'فولكس فاجن', ['Polo', 'Golf', 'Jetta', 'Passat', 'T-Roc', 'Tiguan']),
    CarMake('Opel', 'أوبل', ['Astra', 'Corsa', 'Insignia', 'Mokka', 'Crossland', 'Grandland']),
    CarMake('Geely', 'جيلي', ['Emgrand', 'Coolray', 'GX3', 'Tugella', 'Okavango']),
    CarMake('Haval', 'هافال', ['Jolion', 'H6', 'H9']),
    CarMake('Jetour', 'جيتور', ['X70', 'X90', 'Dashing']),
    CarMake('Changan', 'شانجان', ['Alsvin', 'Eado', 'CS35', 'CS75']),
    CarMake('Proton', 'بروتون', ['Saga', 'Persona', 'X50', 'X70']),
    CarMake('Honda', 'هوندا', ['City', 'Civic', 'Accord', 'HR-V', 'CR-V', 'Pilot', 'Odyssey']),
    CarMake('Mazda', 'مازدا', ['3', '6', 'CX-3', 'CX-30', 'CX-5']),
    CarMake('Ford', 'فورد', ['Fiesta', 'Focus', 'Fusion', 'Taurus', 'EcoSport', 'Territory', 'Kuga', 'Edge', 'Explorer', 'Expedition', 'Bronco', 'Ranger', 'F-150', 'Mustang']),
    CarMake('Citroën', 'ستروين', ['C-Elysée', 'C3', 'C4', 'C5 Aircross']),
    CarMake('Seat', 'سيات', ['Ibiza', 'Leon', 'Arona', 'Ateca']),
    CarMake('Jeep', 'جيب', ['Renegade', 'Compass', 'Cherokee', 'Grand Cherokee', 'Wrangler']),
    CarMake('Lexus', 'لكزس', ['ES', 'IS', 'LS', 'UX', 'NX', 'RX', 'GX', 'LX']),
    CarMake('GMC', 'جي إم سي', ['Terrain', 'Acadia', 'Yukon', 'Yukon XL', 'Sierra']),
    CarMake('Cadillac', 'كاديلاك', ['CT4', 'CT5', 'XT4', 'XT5', 'XT6', 'Escalade']),
    CarMake('Dodge', 'دودج', ['Charger', 'Challenger', 'Durango']),
    CarMake('Ram', 'رام', ['1500', '2500']),
    CarMake('Chrysler', 'كرايسلر', ['300', 'Pacifica']),
    CarMake('Lincoln', 'لينكولن', ['Corsair', 'Nautilus', 'Aviator', 'Navigator']),
    CarMake('Infiniti', 'إنفينيتي', ['Q50', 'QX50', 'QX55', 'QX60', 'QX80']),
    CarMake('Genesis', 'جينيسيس', ['G70', 'G80', 'G90', 'GV70', 'GV80']),
    CarMake('Tesla', 'تسلا', ['Model 3', 'Model Y', 'Model S', 'Model X']),
    CarMake('Isuzu', 'إيسوزو', ['D-Max', 'MU-X']),
    CarMake('GAC', 'جي إيه سي', ['GS3', 'GS4', 'GS8', 'Empow', 'GN8']),
    CarMake('Great Wall', 'جريت وول', ['Wingle', 'Poer']),
    CarMake('Tank', 'تانك', ['300', '500']),
    CarMake('Exeed', 'إكسيد', ['LX', 'TXL', 'VX']),
    CarMake('Omoda', 'أومودا', ['C5', 'E5']),
    CarMake('Jaecoo', 'جيكو', ['J7', 'J8']),
    CarMake('Hongqi', 'هونشي', ['H5', 'HS5', 'E-HS9']),
    CarMake('JAC', 'جاك', ['J7', 'JS4', 'T8']),
    CarMake('Dongfeng', 'دونغ فنغ', ['Aeolus', 'Forthing']),
    CarMake('Mercedes', 'مرسيدس', ['A 200', 'C 180', 'C 200', 'C 300', 'E 200', 'E 300', 'S 450', 'S 580', 'CLA', 'GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'G 63', 'V-Class']),
    CarMake('BMW', 'بي إم دبليو', ['116i', '218i', '320i', '330i', '520i', '530i', '740Li', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'M5']),
    CarMake('Audi', 'أودي', ['A3', 'A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7', 'Q8']),
    CarMake('Volvo', 'فولفو', ['S60', 'XC40', 'XC60', 'XC90']),
    CarMake('Land Rover', 'لاند روفر', ['Range Rover', 'Range Rover Sport', 'Velar', 'Evoque', 'Defender', 'Discovery']),
    CarMake('Porsche', 'بورش', ['Macan', 'Cayenne', 'Panamera', '911', 'Taycan']),
    CarMake('Maserati', 'مازيراتي', ['Ghibli', 'Levante', 'Grecale']),
    CarMake('Bentley', 'بنتلي', ['Continental', 'Flying Spur', 'Bentayga']),
    CarMake('Rolls-Royce', 'رولز رويس', ['Ghost', 'Phantom', 'Cullinan']),
    CarMake('Ferrari', 'فيراري', ['Roma', '296', 'Purosangue']),
    CarMake('Lamborghini', 'لامبورغيني', ['Urus', 'Huracán']),
    CarMake('Mini', 'ميني', ['Cooper', 'Countryman']),
    CarMake('Subaru', 'سوبارو', ['Impreza', 'XV', 'Forester']),
    CarMake('Lada', 'لادا', ['Granta', 'Vesta', 'Niva']),
    CarMake('Speranza', 'سبيرانزا', ['A113', 'A516', 'Tiggo']),
    CarMake('Daewoo', 'دايو', ['Lanos', 'Nubira']),
  ];

  static CarMake? make(String? name) {
    if (name == null) return null;
    final key = name.trim().toLowerCase();
    for (final m in makes) {
      if (m.name.toLowerCase() == key) return m;
    }
    return null;
  }

  static List<String> modelsOf(String? make) => CarCatalog.make(make)?.models ?? const [];

  /// Loose match for search: case, Arabic letter forms and digits do not matter.
  static String searchKey(String text) =>
      FormatHelper.normalizePlate(text).toLowerCase().replaceAll('é', 'e').replaceAll('ë', 'e');
}
