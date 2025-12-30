import 'package:intl/intl.dart';

class DateFormatter {
  // Format: dd/MM/yyyy
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format: dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Format: HH:mm
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Format: dd MMMM yyyy (ex: 15 janvier 2024)
  static String formatDateLong(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('dd MMMM yyyy', locale).format(date);
  }

  // Format: EEEE dd MMMM yyyy (ex: Lundi 15 janvier 2024)
  static String formatDateFull(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('EEEE dd MMMM yyyy', locale).format(date);
  }

  // Format: dd MMM yyyy (ex: 15 jan 2024)
  static String formatDateShort(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  // Format: MMMM yyyy (ex: Janvier 2024)
  static String formatMonthYear(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  // Format: yyyy-MM-dd (ISO format for API)
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format: yyyy-MM-ddTHH:mm:ss (ISO DateTime for API)
  static String formatDateTimeISO(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Parse date from string (dd/MM/yyyy)
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Parse datetime from string (dd/MM/yyyy HH:mm)
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  // Parse ISO date string
  static DateTime? parseDateISO(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get relative time (ex: "Il y a 2 heures")
  static String getRelativeTime(DateTime dateTime, {String locale = 'fr'}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Il y a $minutes ${minutes > 1 ? 'minutes' : 'minute'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Il y a $hours ${hours > 1 ? 'heures' : 'heure'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Il y a $days ${days > 1 ? 'jours' : 'jour'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks ${weeks > 1 ? 'semaines' : 'semaine'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months ${months > 1 ? 'mois' : 'mois'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years ${years > 1 ? 'ans' : 'an'}';
    }
  }

  // Get day name (ex: "Lundi")
  static String getDayName(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('EEEE', locale).format(date);
  }

  // Get month name (ex: "Janvier")
  static String getMonthName(DateTime date, {String locale = 'fr_FR'}) {
    return DateFormat('MMMM', locale).format(date);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Get formatted date with context (Aujourd'hui, Hier, etc.)
  static String getContextualDate(DateTime date, {String locale = 'fr_FR'}) {
    if (isToday(date)) {
      return 'Aujourd\'hui';
    } else if (isYesterday(date)) {
      return 'Hier';
    } else if (isTomorrow(date)) {
      return 'Demain';
    } else {
      return formatDate(date);
    }
  }

  // Get age from birthdate
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week
  static DateTime getStartOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return getStartOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  // Get end of week
  static DateTime getEndOfWeek(DateTime date) {
    final daysToAdd = 7 - date.weekday;
    return getEndOfDay(date.add(Duration(days: daysToAdd)));
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  // Get number of days in month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  // Add months to date
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  // Add years to date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }

  // Calculate difference in days
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Get list of dates between two dates
  static List<DateTime> getDatesBetween(DateTime startDate, DateTime endDate) {
    final dates = <DateTime>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  // Format duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}