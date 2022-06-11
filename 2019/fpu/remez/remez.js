"use strict";
// Remez evaluation code taken from:
// https://github.com/olessavluk/yotodo

function EvaluateInScope(codeText){
    var abs = Math.abs;
    var sqrt = Math.sqrt;
    var exp = Math.exp;
    var ln = Math.log;
    var log10 = log10;
    var log2  = Math.log2;
    var pow = Math.pow;
    var sin = Math.sin;
    var cos = Math.cos;
    var tan =  Math.tan;
    var atan = Math.atan;
    var atan2 = Math.atan2;
    var asin = Math.asin;
    var acos = Math.acos;
    var sinh = Math.sinh;
    var cosh = Math.cosh;
    var acosh = Math.acosh;
    var asinh = Math.asinh;
    var tanh = Math.tanh;
    var Result;
    eval("Result = function (x){ return (" + codeText + ");};");
    return Result;
}

function GetRemezPoints(evalFunc, intervalStart, intervalEnd, degrees){
    var points = [];
    for (var i = 0; i < degrees + 2; i++) {
        // Find the Chevishev nodes and map them to our interval
        var p = (intervalStart + intervalEnd + (intervalEnd - intervalStart) * Math.cos(Math.PI * i / (degrees+1))) / 2;
        var fp = evalFunc(p);
        points.push([p, fp]);
    }
    return points;
}

function range(n){
    var Result = new Array(n);
    for(var i=0;i<n;i++){
        Result[i] = i;
    }
    return Result;
}

/**
 * linear equation solver using gauss method
 *
 * @param matrix
 * @param freeTerm
 * @returns {Array}
 */
var gauss = function (matrix, freeTerm) {
  var n = freeTerm.length,
    resX = new Array(n);

  var swap = function (x, y) {
    var tmp = 0;
    for (var i = 0; i < n; i++) {
      tmp = matrix[x][i];
      matrix[x][i] = matrix[y][i];
      matrix[y][i] = tmp;
    }
    tmp = freeTerm[x];
    freeTerm[x] = freeTerm[y];
    freeTerm[y] = tmp;
  };

  // Straight course
  for (var i = 0; i < n - 1; i++) {
    if (matrix[i][i] === 0) {
      for (var j = i + 1; j < n && matrix[i][i] === 0; j++) {
        if (matrix[j][i] !== 0) {
          swap(i, j);
        }
      }
    }
    for (var j = i + 1; j < n; j++) {
      var coef = matrix[j][i] / matrix[i][i];
      for (var k = i; k < n; k++) {
        matrix[j][k] -= matrix[i][k] * coef;
      }
      freeTerm[j] -= freeTerm[i] * coef;
    }
  }

  // Reverse course
  resX[n - 1] = freeTerm[n - 1] / matrix[n - 1][n - 1];
  for (var i = n - 2; i >= 0; i--) {
    resX[i] = 0.0;
    for (var j = i + 1; j < n; j++) {
      resX[i] += matrix[i][j] * resX[j];
    }
    resX[i] = (freeTerm[i] - resX[i]) / matrix[i][i];
  }

  return resX;
};

function polynomialToFunc (coeffs) {
    return function(x){   
        var Result = coeffs[coeffs.length-1];
        for(var i=coeffs.length - 2 ;i>=0; i--){
            Result = coeffs[i] + x * Result;
        }
        return Result;
    }
}

function polynomialToCode(coeffs){
    var Result = coeffs[coeffs.length-1].toString();
    for(var i=coeffs.length - 2 ;i>=0; i--){
        Result = coeffs[i].toString() + " + x*(" + Result + ")";
    }
    Result = "y = " + Result;
    return Result;
}


/**
 * Least Squares approximation method
 *
 * @param points points of func to be approx
 * @param degree approx polynomial degree
 *
 * @returns Array coefficients of polynomial
 */
function leastSquaresPolynomial(points, degree) {
  var total = points.length,
    tmp = 0;

  var matrix = new Array(degree),
    freeTerm = [];
  for (var j = 1; j <= degree; j++) {
    matrix[j - 1] = [];
    for (var i = 1; i <= degree; i++) {
      tmp = 0;
      for (var l = 1; l < total; l++) {
        tmp += Math.pow(points[l][0], i + j - 2);
      }
      matrix[j - 1].push(tmp);
    }

    tmp = 0;
    for (var l = 1; l < total; l++) {
      tmp += points[l][1] * Math.pow(points[l][0], j - 1);
    }
    freeTerm.push(tmp);
  }

  return gauss(matrix, freeTerm);
}

/**
 * Remez approximation algorithm - https://en.wikipedia.org/wiki/Remez_algorithm
 *
 * @param points points of func to be approx
 *
 * @returns Array coefficients of polynomial
 */
function remezPolynomial (points, origFunc) {
    var total = points.length;
    var degree = total - 2;
    var freeTerm = points.map(point => point[1]);

    var matrix = points.map((point, index) =>
        range(degree + 2)
          .map(i =>
            (degree - i >= 0) ? Math.pow(point[0], degree - i) : Math.pow(-1, index)
        ) // x^degree, x^degree-1, ..., x^0, -1^row
    );

    // Get the tentative polynomial coefficients
    var coeffs = gauss(matrix, freeTerm).slice(0, -1).reverse();
    return coeffs;
}

function PaintAbsError(canvas, intervalS, intervalE, origF, approxF){

    var pointCnt = 600;
    var points = new Array(pointCnt);

    for(var i=0; i<pointCnt;i++){
        var x = intervalS + i/(pointCnt-1) * (intervalE-intervalS);
        var y0 = origF(x);
        var y1 = approxF(x);
        var err = Math.abs(y1 - y0);
        points[i] = [x,err];
    }

    // Draw Graph
    var graph = Flotr.draw(document.getElementById("errorgraph"), [ points ], {
      xaxis: {
      }, 
      grid: {
        minorVerticalLines: true,
        minorHorizontalLines: true
      }
    });
}

function PaintFunctions(canvas, intervalS, intervalE, origF, approxF){

    var pointCnt = 600;
    var points1 = new Array(pointCnt);
    var points2 = new Array(pointCnt);


    for(var i=0; i<pointCnt;i++){
        var x = intervalS + i/(pointCnt-1) * (intervalE-intervalS);
        points1[i] = [x,origF(x)];
        points2[i] = [x,approxF(x)];
    }

    // Draw Graph
    var graph = Flotr.draw(document.getElementById("functiongraph"), [ points1, points2 ], {
      colors:["#0F0", "#F00"],
      shadowSize:0,
      xaxis: {
      }, 
      grid: {
        minorVerticalLines: true,
        minorHorizontalLines: true
      }
    });

}

function CalculateErrorValues(form, start, end, f1, f2){
    var maxErr = 0;
    var maxRelErr = 1;
    var iters = 50000; 
    for(var i=0;i<iters ;i++){
        var x = start + (end-start) * i / (iters-1);
        var err = Math.abs(f1(x) - f2(x));
        maxErr = Math.max(maxErr, err);
    }
    form.AbsErr.value = maxErr;
}

function GetCoeffs(){
    var Result = [];
    var elems = document.getElementsByClassName("coefficient");
    for(var i=0;i<elems.length;i++){
        var v = elems[i].value;
        if(v == ""){
            v= '0';
        }
        var f = parseFloat(v)
        Result.push(f);
    }
    return Result;
}

function RedrawAll(){
    var form = document.forms[0];
    var start = parseFloat(form.iStart.value);
    var end = parseFloat(form.iEnd.value);
    var expr = form.Expr.value;

    var evalFunc = EvaluateInScope(expr);

    var Coeffs = GetCoeffs();
    form.Output.value = polynomialToCode(Coeffs);

    var ResultFunc = polynomialToFunc(Coeffs);
    var canvas= document.getElementById("mainCanvas");
    PaintFunctions(canvas, start, end, evalFunc, ResultFunc);
    var errCanvas = document.getElementById("errCanvas");
    PaintAbsError(errCanvas, start, end, evalFunc, ResultFunc);
    CalculateErrorValues(form, start, end, evalFunc, ResultFunc);
}

function DegreesChanged(newValue){
    var CoeffsDiv = document.getElementById("Coefficients");
    CoeffsDiv.innerHTML = '';
    for(var i=0;i<=newValue;i++){
        var l = document.createElement("label");
        l.innerHTML = "<br/>Degree " + i + "&nbsp;";
        CoeffsDiv.appendChild(l);

        var d = document.createElement("input");
        d.type = "text";
        d.id = "Coeff_" + i;
        d.className = "coefficient";
        d.oninput = RedrawAll;
        CoeffsDiv.appendChild(d);
    }
}


function CalculateFormRemez(){
    // Clear error messages
    document.getElementById("warning").innerHTML = "";

    var form = document.forms[0];
    var start = parseFloat(form.iStart.value);
    var end = parseFloat(form.iEnd.value);
    var degrees = parseInt(form.Degrees.value);
    var expr = form.Expr.value;
    
    DegreesChanged(degrees);
    var evalFunc = EvaluateInScope(expr);
    var initialPoints = GetRemezPoints(evalFunc, start, end, degrees);
    var ResultCoeffs;

    var maxRetries = 10;
    var retryCnt = 0;
    for(var retryCnt = 0; retryCnt < maxRetries; retryCnt++){
        ResultCoeffs = remezPolynomial(initialPoints, evalFunc);
        // If we reach NaNs, break out
        if(!ResultCoeffs.every(x=>!isNaN(x))){
            break;
        }

        // Find points with biggest absolute error
        var M=[];

        var newf = polynomialToFunc(ResultCoeffs);
        var errorf = function(x){ return Math.abs(evalFunc(x) - newf(x)); };
        //var errorf = function(x){ return Math.abs(evalFunc(x) - newf(x)) / Math.abs(evalFunc(x)); };
        
        var rangeSplits = 50000;
        var epsilon = (end-start) / rangeSplits;

        // TODO - improve this with a couple rounds of root-finding using Newton's, 
        // instead of just brute-forcing over the range and keeping the found values
        for(var i=0;i<rangeSplits;i++){
            var p=start + (end-start) * i / rangeSplits;
            var fp = errorf(p);
            if(fp >= errorf(p-epsilon) && fp > errorf(p+epsilon)){
                M.push(p);
            }
        }

        var totalError = 0;
        for(var i=1; i < M.length ;i++){
            totalError += Math.abs(M[0] - M[i]);
        }
        
        if(M.length == initialPoints.length-2){
            M.unshift(start);
            M.push(end);
        }       
        if(M.length == initialPoints.length-1){
            M.push(end);
        } 

        if(M.length != initialPoints.length){
            document.getElementById("warning").innerHTML = "ERROR: Could not find maximum error points for next iteration";
            //ResultCoeffs = initialPoints.map(b=>b[0]);
            break;
        }


        for(var i=0;i<M.length;i++){
            initialPoints[i] = [M[i], evalFunc(M[i])];
        }
        retryCnt++;
    }

    // Display coefficients in form
    for(var i=0;i<ResultCoeffs.length;i++){
        var t = document.getElementById("Coeff_" + i);
        t.value = ResultCoeffs[i];
    }
    RedrawAll();
}

window.onload = function(){
    DegreesChanged(parseInt(document.forms[0].Degrees.value) + 1);
    document.getElementById("CalculateButton").click();
}
