import axios from 'axios';
import * as cheerio from 'cheerio';

const url = 'https://www.myneta.info/TamilNadu2021/index.php?action=summary';

const run = async () => {
  const response = await axios.get(url, { timeout: 20000 });
  const $ = cheerio.load(response.data);

  const hrefs = $('a[href]')
    .map((_, element) => $(element).attr('href'))
    .get()
    .filter(Boolean);

  console.log('Total links:', hrefs.length);
  console.log('candidate.php links:', hrefs.filter((h) => h.includes('candidate.php')).length);
  console.log('show_cand links:', hrefs.filter((h) => h.includes('show_cand')).length);
  console.log('Sample links:', hrefs.slice(0, 20));
  console.log(
    'Sample candidate links:',
    hrefs.filter((h) => h.includes('candidate.php')).slice(0, 20)
  );
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
