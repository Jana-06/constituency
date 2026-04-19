import axios from 'axios';
import * as cheerio from 'cheerio';

const run = async () => {
  const url = 'https://www.myneta.info/TamilNadu2021/index.php?action=summary';
  const response = await axios.get(url, { timeout: 20000 });
  const $ = cheerio.load(response.data);

  const links = $('a[href*="candidate.php"]').slice(0, 10);
  links.each((index, element) => {
    const link = $(element);
    const parents = [];
    let node = element;
    for (let i = 0; i < 4 && node; i += 1) {
      const parent = $(node).parent();
      if (!parent.length) break;
      parents.push({
        tag: parent.get(0)?.tagName,
        class: parent.attr('class') || null,
        text: parent.text().replace(/\s+/g, ' ').trim().slice(0, 200),
      });
      node = parent.get(0);
    }

    console.log('LINK', index + 1, link.attr('href'), link.text().trim());
    console.log(JSON.stringify(parents, null, 2));
  });
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

