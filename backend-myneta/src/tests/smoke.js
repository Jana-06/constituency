const baseUrl = process.env.SMOKE_BASE_URL || 'http://127.0.0.1:8080';

const check = async (path) => {
  const response = await fetch(`${baseUrl}${path}`);
  const body = await response.json();
  return {
    path,
    status: response.status,
    ok: response.ok,
    sample: JSON.stringify(body).slice(0, 200),
  };
};

const run = async () => {
  const paths = ['/health', '/constituencies'];
  const results = [];

  for (const path of paths) {
    try {
      results.push(await check(path));
    } catch (error) {
      results.push({ path, ok: false, status: 0, sample: error.message });
    }
  }

  for (const row of results) {
    console.log(`${row.ok ? 'PASS' : 'FAIL'} ${row.path} status=${row.status} sample=${row.sample}`);
  }

  const failed = results.some((row) => !row.ok);
  process.exit(failed ? 1 : 0);
};

run();

