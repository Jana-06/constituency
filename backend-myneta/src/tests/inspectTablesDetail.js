import axios from 'axios';
import * as cheerio from 'cheerio';

const run = async () => {
  const url = 'https://www.myneta.info/TamilNadu2021/index.php?action=summary';
  const response = await axios.get(url, { timeout: 20000 });
  const $ = cheerio.load(response.data);

  let idx = 0;
  $('table').each((_, table) => {
    const candidateLinks = $(table).find('a[href*="candidate.php"]').length;
    if (candidateLinks > 0) {
      idx += 1;
      const rows = $(table).find('tr').length;
      const firstRow = $(table)
        .find('tr')
        .eq(1)
        .find('td')
        .map((_, cell) => $(cell).text().replace(/\s+/g, ' ').trim())
        .get();
      console.log(`TABLE ${idx}: links=${candidateLinks}, rows=${rows}, firstRow=${JSON.stringify(firstRow)}`);
    }
  });
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

