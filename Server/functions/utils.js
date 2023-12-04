//Takes a date object and turns it into MM/DD/YYYY format
function americanDateFormatter(date) {
  // Get the month, day, and year from the Date object
  let month = date.getMonth() + 1; // getMonth() returns 0-11
  let day = date.getDate();
  const year = date.getFullYear();

  // Format the month and day to ensure two digits
  month = month < 10 ? "0" + month : month;
  day = day < 10 ? "0" + day : day;

  // Concatenate to get the date in MM/DD/YYYY format
  const formattedDate = year + "-" + month + "-" + day;
  return formattedDate;
}

function capitalizeFirstLetter(text) {
  return text[0].toUpperCase() + text.substring(1, text.length);
}

module.exports = { americanDateFormatter, capitalizeFirstLetter };
