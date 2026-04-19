import axios from 'axios';

const run = async () => {
  const response = await axios.get('https://www.myneta.info/TamilNadu2021/index.php?action=summary', {
    timeout: 20000,
  });

  const html = String(response.data);
  const matches = [...html.matchAll(/index\.php\?action=summary[^"'#\s]*/g)].map((m) => m[0]);
  const unique = Array.from(new Set(matches));

  console.log('Summary link count:', unique.length);
  console.log(unique.slice(0, 100));
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

