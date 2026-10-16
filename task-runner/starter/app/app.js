// Draws the homework table from data.js.
function render(list) {
  const rows = document.getElementById("rows");
  rows.innerHTML = "";
  for (const hw of list) {
    const tr = document.createElement("tr");
    tr.innerHTML =
      "<td>" + hw.subject + "</td>" +
      "<td>" + hw.title + "</td>" +
      "<td>" + hw.due + "</td>" +
      "<td>" + (hw.done ? "Done" : "Pending") + "</td>";
    rows.appendChild(tr);
  }
}

render(homework);
