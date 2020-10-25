class Translator {
  static const mealTypes = {
    'breakfast': 'śniadanie',
    'lunch': 'obiad',
    'dinner': 'kolacja',
    'snack': 'przekąska',
  };

  static String mealType(String org){
    return mealTypes[org.toLowerCase()];
  }
}