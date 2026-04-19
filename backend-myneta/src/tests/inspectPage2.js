import axios from 'axios';

const run = async () => {
  const url = 'https://www.myneta.info/TamilNadu2021/index.php?action=summary&subAction=&sort=&page=2';
  const response = await axios.get(url, { timeout: 20000 });
  const html = String(response.data);
  console.log('length', html.length);
  console.log(html.slice(0, 1000));
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

