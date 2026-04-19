import axios from 'axios';
import * as cheerio from 'cheerio';

const url = 'https://www.myneta.info/TamilNadu2021/index.php?action=summary';

const run = async () => {
  const response = await axios.get(url, { timeout: 20000 });
  const $ = cheerio.load(response.data);

  let targetTable = null;
  $('table').each((_, tbl) => {
    if ($(tbl).find('a[href*="candidate.php"]').length > 0 && !targetTable) {
      targetTable = tbl;
    }
  });

  if (!targetTable) {
    throw new Error('No candidate table found');
  }

  const table = $(targetTable);

  const headers = table
    .find('tr')
    .first()
    .find('th,td')
    .map((_, cell) => $(cell).text().replace(/\s+/g, ' ').trim())
    .get();

  console.log('Headers:', headers);

  const rows = table.find('tr').slice(1, 6);
  rows.each((i, row) => {
    const values = $(row)
      .find('td')
      .map((_, cell) => $(cell).text().replace(/\s+/g, ' ').trim())
      .get();

    const href = $(row).find('a[href*="candidate.php"]').attr('href');
    console.log(i + 1, values, href);
  });
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
