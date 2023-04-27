<%@ page contentType="text/html; charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.3/jquery.min.js"></script>
<script src="https://code.jquery.com/ui/1.13.2/jquery-ui.js" type="text/javascript"></script>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
<script type="text/javascript" src="//dapi.kakao.com/v2/maps/sdk.js?appkey=806e918783759197bca10fffa91fc3e5"></script>
<link href="<%=request.getContextPath()%>/css/planner.css" rel="stylesheet">
<script>
  let lat = [];
  let lon = [];
  let latlon = [];
  let markers = []; //마커 담을 배열
  let customOverlays = [];
  let polylines = []; // 경로 담을 배열
  let colors = [
    '#FFAE00', '#0022ff', '#aa00ff', '#ff003b',
    '#00ff0d', '#c8ff00', '#36fcff', '#480148',
    '#1f2c70', '#1f702a', '#42ff5c', '#42b7ff',
    '#424bff', '#ff42e6'
  ];
  let moreList = document.createElement("div");
  moreList.id = "moreList";
  moreList.innerText = "더보기";

  let savePlan = {};
  let random_color = [];
  $(function () {
    // 저장 눌렀을 때 플랜 이름 있는지 확인
    $("#modalopen").trigger("click");
    $("#newPlannerChoose").click(function(){
      $("#choose_modal_close").trigger("click");
    })

    $("#oldPlannerChoose").click(function(){
      $("#planList").css("display", "block");
      $("#chooseModal").css("z-index","900");


      $.ajax({
        url:'planList',
        type: 'POST',
        success: function (result) {
          console.log(result)
          showPlanList(result)
        }, error: function (e) {
         console.log(e.responseText)
        }
      })
      
      function showPlanList(data){
        $(data).each(function(i, dto){
          let planEl = document.createElement("div"),
              tag = "";

          planEl.className="plan_container";
          tag+="<input type='hidden' class='plan_no' value='"+dto.plan_no+"'/>";
          tag+="<div class='plan_item'>"+dto.plan_name+"</div>";
          tag+="<div class='plan_item'>"+dto.start_date+" - " +dto.end_date + "</div>";
          tag+="<div class='plan_item'>"+dto.plan_name+"</div>";
          tag+="<div class='plan_item planChoose'>선택</div>";
          $(planEl).append(tag);
          $("#planListBody").append(planEl);

        })

      }

    })
    $(document).on("click", ".planChoose", function(){
      let plan_no = $(this).siblings("plan_no").val()


    })

    let pageNo = 1;


    let start = {}; // 시작날짜를 연/월/일로 나눠서 담을 배열
    let startdate;  // 시작날짜를 담을 Date 객체
    let end = {};   // 종료날짜를 연/월/일로 나눠서 담을 배열
    let enddate;    // 종료 날짜를 담을 Date 객체
    let days = 0;   // 두 날짜의 차이를 담을 변수
    $("#start_date").change(function () { // 시작날짜의 변화가 생기면
      $("#schedule").empty(); // 먼저 초기화하고
      start = $("#start_date").val().split('-');  // 선택한 날짜를 '-' 를 기준으로 나눠서 배열에 넣고
      startdate = new Date(start[0], start[1], start[2]);// 그걸 다시 Data 객체로 만듬
      if (enddate != null) {// 만약 종료일이 선택되어있으면
        days = 1 + (enddate.getTime() - startdate.getTime()) / (1000 * 60 * 60 * 24);// 두 날짜의 차이를 구해서
        $("#days").val(days);
        showSchedule(days);// 일정을 선택할수있는 함수에 넣는다.
      }
    });
    $("#end_date").change(function () { // 시작일과 동일한 방식
      $("#schedule").empty();

      end = $("#end_date").val().split('-');
      enddate = new Date(end[0], end[1], end[2]);
      if (startdate != null) {
        days = 1 + (enddate.getTime() - startdate.getTime()) / (1000 * 60 * 60 * 24);
        $("#days").val(days);

        showSchedule(days);

      }

    });

    function colorSetup(days) {
      random_color = [];
      var num;
      do {
        num = Math.floor(Math.random() * colors.length);
        random_color.push(colors[num]);
        for (var i = 0; i < colors.length; i++) { // 중복된 값이 들어가지 않도록 result 배열에 저장된 값은 arr 배열에서 제거
          if (random_color[random_color.length - 1] == colors[i]) {
            colors.splice(i, 1);
          }
        }
      } while (random_color.length != days); // result 배열의 요소가 6개가 될 때까지 반복
      random_color.sort(function (a, b) { // 오름차순으로 정렬
        return a - b;
      });
      return random_color;
    }


    $(document).on("click", "#save", function () {
      if ($("#plan_name").val() === "") {
        alert("플랜 이름을 작성해주세요");
        return false;
      }

      savePlan.plan_name = $("#plan_name").val();
      savePlan.start_date = $("#start_date").val();
      savePlan.end_date = $("#end_date").val();
      savePlan.days =  days;

      let schedule =[];

      for (let i = 0; i < $("#schedule").children().length; i++) {
        for (let j = 0; j < $(".schedule_detail").eq(i).find(".place").length; j++) {
          let place = {place_no:$(".schedule_detail").eq(i)
                    .find(".place").eq(j).find(".place_no").val(),
            days_order:(i + 1),
            course_order:(j+1)
          };

          schedule.push(place);

        }

      }


      savePlan.schedule = JSON.stringify(schedule);

      console.log(savePlan);

      $.ajax({
        url:'/jejuana/planSave',
        data :savePlan,
        type:"POST",

        success: function (result) {
          console.log(result);
        },error:function (e){
          console.log(e.responseText);
        }

      })






    });


    function showSchedule(days) {
      colorSetup(days);// 시작일과 종료일의 차이로 여행 날짜수 구해준값을 파라미터로 넣고
      for (let i = 1; i <= days; i++) {// 날수+1 번 반복해서 코스를 짤 수 있는 블럭을 넣어줌
        let tag = "<div class='schedule_detail'>";
        tag += "<input type='hidden' class='days_order' value='" + i + "'/>";
        tag += "<div class='schedule_header'><div class='day' style='border-bottom-color:" + random_color[i - 1] + "' >Day" + i + "</div></div>";
        tag += "<div class='schedule_body' id='day" + i + "'></div>";
        tag += "<div class='schedule_footer'>";
        tag += "<div class='placeAdd' id='" + i + "'>";
        tag += "<img src='<%=request.getContextPath()%>/img/placeselect.png' width='50'/></div>";
        tag += "</div></div>";
        $("#schedule").append(tag);
      }
    }


    $(document).on("click", ".closeModal", function () { //모달 닫는 버튼
      $("#myModal").css("display", "none");
    });
    $(document).on("click", ".placeAdd", function () { // 장소 추가 버튼을 누르면
      $("#day").val($(this).attr("id"));
      pageNo=1;
      $("#searchWord").attr("class", "placeList");
      $("#selectedPlace").html("");
      $("#placeBox").html("");
      $("#searchWord").val("");// selectedPlace 박스 초기화
      $("#myModal").css("display", "block");// 그리고 모달을 보이게 한다.
      let searchWord = $("#searchWord").val();
      placeList(searchWord, pageNo);                                  //목록 띄워주기
    });

    // 모달 내 여행지 목록에서 여행지 선택 버튼을 눌렀을 때
    $(document).on("click", ".btn-primary", function () { //선택을 누르면
      let selected = $(this).parent().parent();
      $("#selectedPlace").append(selected[0].firstChild); //선택된 여행지를 selectedPlace 박스에 사진으로 올린다.
      selected.css("display", "none"); //선택된 여행지를 목록에서 안보이게 한다.

    });

    function placeList(searchWord, pageNo) {  //장소를 DB에서 불러와서 보여주는 함수

      let url = "placeSelectList";
      let data = "&searchWord="+searchWord+"&pageNo="+pageNo;
      $.ajax({
        url: url,
        type: "POST",
        data: data,
        success(result) {
          showplaces(result);
          if(result.length>=15) {
            $("#placeBox").append(moreList);
          }
        }, error(e) {
          console.log(e.responseText);
        }

      })
    }
    function bookmarkList(searchWord, pageNo) {  //장소를 DB에서 불러와서 보여주는 함수

      let url = "bookmarkList";
      let data = "&searchWord="+searchWord+"&pageNo="+pageNo;
      $.ajax({
        url: url,
        type: "POST",
        data: data,
        success(result) {
          showplaces(result);
          if(result.length>=15) {
            console.log("check");
            $("#placeBox").append(moreList);
          }
        }, error(e) {
          console.log(e.responseText);
        }

      })
    }
    function showplaces(data){
      $("#moreList").remove();
      $(data).each(function (idx, dto) {
        let tag = "<div class='place_container'>";
        tag += "<div class='place_item'>";
        tag += "    <input type='hidden' value='" + dto.place_no + "'/> ";
        tag += "    <img src='<%=request.getContextPath()%>/img/" + dto.thumbnail + "' width='70' height='70'/></div>";
        tag += "<div class='place_item'>";
        tag += "    <span style='font-size: 1.2em'>" + dto.place_name + "</span></div>";
        tag += "<div class='place_item'>" + dto.content + "</div>";
        tag += "<div class='place_item'>";
        tag += "    <button type='button' class='btn btn-primary'>선택</button></div>";

        $("#placeBox").append(tag);

      });

    }


    $(document).on("keypress", "#searchWord", function () { // 검색어를 입력하고 enter를 치면 검색되도록하는 이벤트
      if (event.keyCode == 13) {
        $("#placeBox").html("");
        let searchWord = $("#searchWord").val();
        console.log(searchWord);
        pageNo=1;
        if($("#searchWord").attr("class") =="placeList"){
          placeList(searchWord, pageNo);
        }
        if($("#searchWord").attr("class") =="bookmarkList"){
          bookmarkList(searchWord, pageNo);
        }
      }
    });
    let lat1 = null, lat2 = null, lon1 = null, lon2 = null;

    // 스케줄러에 넣어준 장소를 제거했을 경우
    $(document).on("click", ".place_del", function () {
      let idName = $(this).attr("class").substring(10);
      $(this).parent(".place").remove();
      let target = document.getElementById(idName);

      deleteMarkers();
      deletePolylines();
      $(target).trigger("change");

    });


    $("#saveBtn").click(function () {  //장소를 다 고르고 저장 버튼을 누르면 선택된 여행지가 해당 날짜로 들어감
      // 저장을 누르면
      // 1. selectedPlace에 옮겨진 장소를 plannerbody의 일정부분에 옮기기
      let selectedNo = "";
      let selectedPlace = $("#selectedPlace input");
      for (let i = 0; i < selectedPlace.length; i++) {
        selectedNo += "&places=" + selectedPlace[i].value
      }
      let day = "day" + $("#day").val();
      deleteMarkers()   //마커 다 지우고 마커 배열 빈상태
      deletePolylines();  //경로 다 지우고 경로 배열 빈상태
      schedule_setup(selectedNo, day);  // selectedPlace에 있던것 여행지 번호 모아서 서버에서 데이터 받아와서 세팅
      //마커 & 경로 표시
      // displayMarker(places);  // 순서대로 lat,lon 배열에 넣어서 세팅


      // 2. modalbody에 내용 초기화
      $("#searchWord").val(""); //검색창 초기화
      $("#placeBox").empty();
      $("#selectedPlace").empty();
      // 3. modal을 닫는다.
      $("#myModal").css("display", "none");
    });


    function schedule_setup(selectedNo, day) {

      let target = document.getElementById(day); // 해당 .schedule_body  자리
      let a = target.childElementCount;
      $.ajax({
        url: 'selectedPlace',
        data: selectedNo,
        traditional: true,
        type: 'POST',
        success(result) {
          $(result).each(function (i, dto) {
            let tag = "<div class='place " + day + "'>";
            tag += "<input type='hidden' class='course_order' name='course_order'  value='" + (i + 1 + a) + "'/>";
            tag += "<div class='place_dis'></div>";
            tag += "<div class='place_name'>" + dto.place_name + "</div>";
            tag += "<div class='place_del " + day + "'>삭제</div>";
            tag += "<input type='hidden' class='place_no' name='place_no' value='" + dto.place_no + "'/>";
            tag += "<input class='lat' type='hidden' value='" + dto.latitude + "'/>";
            tag += "<input class='lon'  type='hidden' value='" + dto.longitude + "'/></div>";

            target.innerHTML += tag;
          });
          $(target).trigger("change");
        }, error(e) {
        }
      })


    }

    // $(".schedule_body").sortable();
    $("#selectedPlace").sortable();

    $(document).on("change", ".schedule_body", function () {
      latlon = [];
      lat = [];
      lon = [];
      $(this).find(".place").each(function (i, place) {
        lat.push($(place).find(".lat").val());
        lon.push($(place).find(".lon").val())
        latlon.push(new kakao.maps.LatLng(lat[i], lon[i]))
        if (i > 0) {
          let dis = parseInt(distance(lat[i - 1], lon[i - 1], lat[i], lon[i]));
          $(place).find(".place_dis").html("");
          $(place).find(".place_dis").append(dis + "KM");
        }
        displayMarker(latlon[i], i + 1);
      })
      drawPath(latlon, random_color[parseInt($(this).siblings(".days_order").val()) - 1]);

    });
    $("#place_tab").click(function(){
      $("#selectedPlace").html("");
      $("#placeBox").html("");
      pageNo = 1;
      $("#searchWord").attr("class", "placeList");
      $("#searchWord").val("");// selectedPlace 박스 초기화
      let searchWord = $(this).serialize();
      placeList(searchWord, pageNo);
    });
    $("#bookmark_tab").click(function(){
      $("#selectedPlace").html("");
      $("#placeBox").html("");
      pageNo = 1;
      $("#searchWord").attr("class", "bookmarkList");
      $("#searchWord").val("");// selectedPlace 박스 초기화
      let searchWord = $(this).serialize();
      bookmarkList(searchWord, pageNo);
    })
    $(document).on("click",".schedule_detail",function(){
      $(".schedule_detail").css("border", "1px solid gray");
      $(this).css("border","3px solid #C1584A");
      let target = $(this).find(".schedule_body");

      deleteMarkers();
      deletePolylines();
      $(target).trigger("change");

    });
    $(document).on("click", "#moreList", function(){
      console.log("clicked");
      pageNo++;
      let searchWord =$("#searchWord").val();
      if($("#searchWord").attr("class") =="placeList"){
        placeList(searchWord, pageNo);
      }
      if($("#searchWord").attr("class") =="bookmarkList"){
        bookmarkList(searchWord, pageNo);
      }
    });
  });


</script>

<div id="planner_body">
  <ul>
    <li>
      <div class="label">플랜이름:</div>
      <input type="text" class="ib" id="plan_name" name="plan_name" placeholder="플랜 이름"/></li>
    <li>
      <div class="label">일정 :</div>
      <input type="date" id="start_date" name="start_date" value=""/>
      - <input type="date" id="end_date" name="end_date" value=""/></li>
    <li><input type="hidden" id="days" name="days" value=""/></li>
    <li id="schedule">



    </li>
  </ul>
  <br/>

  <div id="buttons">
    <button type="button" id="save">저장</button>
    <button type="button" id="cancel">취소</button>
  </div>


  <div class="myModal" id="myModal"> <!-- 모달로 쓸 블럭 -->
    <input type="hidden" id="day" value=""/>
    <div id="modalheader">
      <div id="place_tab">여행지</div>
      <div id="bookmark_tab">북마크</div>
    </div>
    <div id="modalbody">

      <button type="button" class="closeModal" id="xbox"><img src="<%=request.getContextPath()%>/img/delete.png"
                                                              width="20"></button>
      <%--검색--%>
      <div id="searchForm" style="background-color: bisque; height:50px;">
        <input type="text" class="placeList" name="searchWord" id="searchWord"/>
      </div>
      <%--선택한거 보여주는 박스--%>
      <div id="selectedPlace">

      </div>
      <div id="placeSave">
        <div id="saveBtn" class="btn button">저장</div>
        <%--이거 누르면 왜 --%>
        <div id="cancelBtn" class="btn button">취소</div>
      </div>
      <%--장소 목록 예시--%>
      <div id="placeBox">

      </div>

    </div>
    <div id="modalfooter">
      <button type="button" class="btn btn-danger closeModal" id="closeBtn" data-bs-dismiss="modal">Close</button>
    </div>
  </div>
</div>
<div id="map"></div>
<div id="planList">
  <div id="planListBody">
    <div class="plan_container">
      <input type="hidden" class="plan_no" value="1234"/>
      <div class="plan_item">플랜이름</div>
      <div class="plan_item">플랜일정</div>
      <div class="plan_item">제일 첫 일정</div>
      <div class="plan_item">선택버튼</div>
    </div>
    <div class="plan_container">
      <input type="hidden" class="plan_no" value="1234"/>
      <div class="plan_item">플랜이름</div>
      <div class="plan_item">플랜일정</div>
      <div class="plan_item">제일 첫 일정</div>
      <div class="plan_item">선택버튼</div>
    </div>
  </div>
</div>
<span style="display: none">
<input type="button" id="modalopen" data-bs-toggle="modal" data-bs-target="#chooseModal" value="모달열기"/>
</span>
<div class="modal fade modal-dialog-centered" id="chooseModal">
  <div class="modal-dialog ">
    <div class="modal-content">

      <!-- Modal Header -->
      <div class="modal-header">
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>

      <!-- Modal body -->
      <div class="modal-body" >
        <input type="button" id="oldPlannerChoose" value="기존 플랜 불러오기">
      </div>
      <div class="modal-body" >
        <input type="button" id="newPlannerChoose" value="플랜 새로만들기" data-bs-dismiss="modal">
      </div>

      <!-- Modal footer -->
      <div class="modal-footer">
        <button type="button" id="choose_modal_close" class="btn btn-danger" data-bs-dismiss="modal">Close</button>
      </div>

    </div>
  </div>
</div>


<script>
  let container = document.getElementById('map'); //지도를 담을 영역의 DOM 레퍼런스
  let options = { //지도를 생성할 때 필요한 기본 옵션
    center: new kakao.maps.LatLng(33.450701, 126.570667), //지도의 중심좌표.
    level: 9 //지도의 레벨(확대, 축소 정도)
  };

  let map = new kakao.maps.Map(container, options); //지도 생성 및 객체 리턴

  let mapTypeControl = new kakao.maps.MapTypeControl();

  // 지도에 컨트롤을 추가해야 지도위에 표시됩니다
  // kakao.maps.ControlPosition은 컨트롤이 표시될 위치를 정의하는데 TOPRIGHT는 오른쪽 위를 의미합니다
  map.addControl(mapTypeControl, kakao.maps.ControlPosition.TOPLEFT);

  // 지도 확대 축소를 제어할 수 있는  줌 컨트롤을 생성합니다
  let zoomControl = new kakao.maps.ZoomControl();
  map.addControl(zoomControl, kakao.maps.ControlPosition.LEFT);


  function displayMarker(position, i) {
    var imageSrc = '<%=request.getContextPath()%>/img/marker.png', // 마커이미지의 주소입니다
            imageSize = new kakao.maps.Size(40, 44), // 마커이미지의 크기입니다
            imageOption = {offset: new kakao.maps.Point(20, 44)}; // 마커이미지의 옵션입니다. 마커의 좌표와 일치시킬 이미지 안에서의 좌표를 설정합니다.

// 마커의 이미지정보를 가지고 있는 마커이미지를 생성합니다
    var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption)

    // 마커를 생성합니다
    var marker = new kakao.maps.Marker({
      position: position,
      image: markerImage
    });

    // 마커가 지도 위에 표시되도록 설정합니다
    marker.setMap(map);

    // 생성된 마커를 배열에 추가합니다
    markers.push(marker);

    var content = "<h5>" + i + "</h5>";

    // 커스텀 오버레이가 표시될 위치입니다


    // 커스텀 오버레이를 생성합니다
    var customOverlay = new kakao.maps.CustomOverlay({
      position: position,
      content: content,
      yAnchor: 1.25
    });
    customOverlay.setMap(map);
    customOverlays.push(customOverlay);
  }

  function deleteMarkers() {
    for (var i = 0; i < markers.length; i++) {
      markers[i].setMap(null);
      customOverlays[i].setMap(null);
    }
    markers = [];
    customOverlays = [];
  }

  function showAllMarkers() {
    for (var i = 0; i < markers.length; i++) {
      markers[i].setMap(map);
    }
  }

  function deletePolylines() {
    for (var i = 0; i < polylines.length; i++) {
      polylines[i].setMap(null);
    }
    polylines = [];
  }

  function showAllPolylines() {
    for (var i = 0; i < polylines.length; i++) {
      ploylines[i].setMap(map);
    }
    markers = [];

  }


  function distance(lat1, lon1, lat2, lon2) { // 거리 구하는 함수
    const R = 6371; // 지구 반지름 (단위: km)
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;// 두 지점 간의 거리 (단위: km)
  }

  function deg2rad(deg) {
    return deg * (Math.PI / 180);
  }


  // 지도에 표시할 선을 생성합니다

  function drawPath(linePath, color) {
    var polyline = new kakao.maps.Polyline({
      path: linePath, // 선을 구성하는 좌표배열 입니다
      strokeWeight: 5, // 선의 두께 입니다
      strokeColor: color, // 선의 색깔입니다
      strokeOpacity: 0.7, // 선의 불투명도 입니다 1에서 0 사이의 값이며 0에 가까울수록 투명합니다
      strokeStyle: 'solid' // 선의 스타일입니다
    });

    // 지도에 선을 표시합니다
    polyline.setMap(map);
    polylines.push(polyline);
  }


</script>

