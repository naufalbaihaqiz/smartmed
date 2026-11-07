import 'medication.dart';
import 'prescription.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_nutrition.dart';
import 'reminder.dart';
import 'reminder_item.dart';

export 'allergy.dart';
export 'health_condition.dart';
export 'medication.dart';
export 'prescription.dart';
export 'recipe.dart';
export 'recipe_ingredient.dart';
export 'recipe_nutrition.dart';
export 'reminder.dart';
export 'reminder_item.dart';

/// Gabungan `Reminder` beserta daftar obat yang harus diminum pada jadwal tersebut.
class ReminderWithItems {
  const ReminderWithItems({
    required this.reminder,
    required this.items,
    required this.medications,
  });

  final Reminder reminder;
  final List<ReminderItem> items;
  final List<Medication> medications;
}

/// Gabungan `Prescription` lengkap dengan seluruh obat dan jadwal pengingatnya.
class PrescriptionDetail {
  const PrescriptionDetail({
    required this.prescription,
    required this.medications,
    required this.reminders,
  });

  final Prescription prescription;
  final List<Medication> medications;
  final List<ReminderWithItems> reminders;
}

/// Gabungan `Recipe` lengkap dengan daftar bahan dan informasi nutrisinya.
class RecipeDetail {
  const RecipeDetail({
    required this.recipe,
    required this.ingredients,
    this.nutrition,
  });

  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  final RecipeNutrition? nutrition;
}

