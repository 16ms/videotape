var content = '';
process.stdin.resume();
process.stdin.on('data', buf => {
  content += buf.toString();
});
process.stdin.on('end', () => {
  try {
    console.log(JSON.parse(content).score > 0.9);
  } catch (e) {
    console.error('content: ', content);
    console.error(e);
  }
  process.exit();
});
