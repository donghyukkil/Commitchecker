<p align="center">
     <img src="./assets/images/lawncheck.png" width="300" height="300">
</p>

# 목차

- [프로젝트 소개](#프로젝트-소개)
- [프로젝트 관심사](#프로젝트-관심사)
  - [MVVM 아키텍처 패턴](#mvvm-아키텍처-패턴)
  - [테스트코드](#테스트코드)
  - [상태관리와 provider](#상태-관리와-provider)
- [기술스택](#기술스택)
- [연락처](#연락처)

<br>

# 프로젝트 소개
- 사용자의 GitHub 커밋 데이터를 시각적으로 표시하며, 선택된 기간 동안의 커밋 통계를 확인할 수 있습니다.

  <p align="center">
     <img src="https://github.com/donghyukkil/Commitchecker/assets/124029691/a196ba0d-06fb-48af-a120-e9c580d99ac7" width="200" height="350">
  </p>


<br>

# 프로젝트 관심사

  - CommitChecker는 토이 프로젝트로 진행되었기 때문에, 단기간에 프로젝트를 완성시키고 싶었습니다. 그래서 새로운 프로그래밍 언어와 프레임워크인 Dart와 Flutter를 공부하고 프로젝트에 원하는 기능을 구현하는 것을 목표로 빠르게 프로젝트의 프로토타입을 완성시켰습니다. 그러다 보니, 기능에 문제가 없다 하더라도 UI와 비즈니스 로직이 엉겨 붙어 있어 테스트코드를 작성하는데 어려움이 많았습니다. 따라서  프로젝트를 갈무리할 무렵, 클린 코드를 위한 아키텍처 패턴을 학습하였습니다. 모바일 앱을 위해 MVVC 패턴의 사용이 권장되는 것을 알게 되었고, MVVM 아키텍처 패턴을 프로젝트에 적용하여 리팩터링을 해보았습니다.

## MVVM 아키텍처 패턴

 - 애플리케이션의 구조를 설계할 때, 개발자는 코드의 유지보수성, 확장성 및 테스트 용이성을 고려해야 합니다. 이를 위해 MVC (Model-View-Controller), MVP (Model-View-Presenter), MVVM (Model-View-ViewModel)과 같은 다양한 아키텍처 패턴이 사용됩니다. 각 패턴은 애플리케이션의 구조를 정의하고, 개발 프로세스를 가이드하는 역할을 합니다.

- MVC, MVP, MVVM 아키텍처 패턴 비교

 <br>

  | 패턴 | 정의 | 특징 | 장점 | 단점 |
  |------|------|------|------|------|
  | MVC | Model, View, Controller 분리 | - Model: 데이터 및 로직 처리<br>- View: UI 담당<br>- Controller: 입력 처리, Model-View 연결 | 가독성 및 관리 용이 | View-Model 의존성, 커질 수 있는 Controller |
  | MVP | MVC 개선, Presenter 도입 | - Model: 데이터 및 로직 처리<br>- View: UI, 입력 Presenter 전달<br>- Presenter: UI 로직, Model-View 업데이트 | View-Model 의존성 감소, 유지보수/테스트 용이 | 복잡한 View-Presenter 상호작용, 비대해질 수 있는 Presenter |
  | MVVM | ViewModel 사용, 데이터 바인딩 지원 | - Model: 데이터 및 로직 처리<br>- View: UI, 입력 ViewModel 전달<br>- ViewModel: 데이터 준비, 명령 처리, Model 업데이트 | 코드 감소, 유지보스/테스트 용이 | 데이터 바인딩 디버깅 어려움, 학습 어려움 |


 - MVVM (Model-View-ViewModel) 아키텍처 패턴은 데이터 바인딩과 유닛 테스트의 용이성 측면에서 장점이 있습니다.

  - 데이터 바인딩의 효율성.
    - MVC와 MVP에서는 View의 업데이트를 위해 Controller나 Presenter가 직접적으로 관련 로직을 호출해야 합니다. 이 과정은 개발자에게 추가적인 작업을 요구하며, UI와 비즈니스 로직의 긴밀한 결합을 유발할 수 있습니다.
    MVVM 아키텍처의 핵심은 데이터 바인딩입니다. 데이터 바인딩은 View와 ViewModel 사이의 자동 동기화를 가능하게 하여, UI와 애플리케이션 로직을 분리합니다. 이는 개발자가 UI 업데이트 로직에 신경 쓰지 않고 비즈니스 로직에 더 집중할 수 있게 해줍니다. 모바일 애플리케이션에서는 사용자 인터페이스가 빈번히 변경되고, 다양한 사용자 상호작용을 처리해야 하므로, 데이터 바인딩을 통한 자동화는 개발 과정을 대폭 간소화합니다.

  - 유닛 테스트의 용이성.
    - MVC와 MVP에서는 Controller와 Presenter가 View와 더 긴밀하게 연결되어 있을 수 있습니다. MVC에서 Controller가 View의 업데이트를 직접 관리하기 때문에, 비즈니스 로직과 UI 로직의 분리가 MVVM만큼 명확하지 않을 수 있습니다. 또한 MVP에서 Presenter는 View와의 인터페이스를 통해 UI 로직을 처리하므로, UI 로직과의 분리 없이 테스트하기가 더 어려울 수 있습니다. 하지만 MVVM은 ViewModel이 View로부터 독립적으로 작동하기 때문에, UI를 거치지 않고도 비즈니스 로직을 테스트할 수 있습니다.

## 테스트코드

### 비즈니스 로직과 UI 로직 분리의 중요성 (MVVM 패턴 적용 X)

  - CommitHeatmap 위젯은 사용자의 GitHub 리포지토리 목록을 가져오는 비즈니스 로직과 이 데이터를 UI에 반영하는 로직을 포함합니다. 이러한 결합은 데이터 처리와 UI 반응 사이의 밀접한 연결로 인해 독립적인 테스트를 어렵게 만듭니다.

    ```
      Future<void> fetchRepositories(String username) async {
        try {
          List<String> repoNames = await fetchRepositoriesFromAPI(
            username,
            client: httpClient,
          );

          setState(
            () {
              repositories = repoNames;

              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _showModal(context));

              selectedRepository =
                  repositories.isNotEmpty ? repositories.first : null;

              fetchCommitsForMonth(
                focusedDay,
              );
            },
          );
        } catch (e) {
          showErrorDialog(
            'Failed to load repositories. \nPlease enter the correct user',
          );
        }
    }

  - fetchRepositoriesFromAPI 함수를 통해 비동기적으로 GitHub 리포지토리 목록을 가져옵니다. 가져온 데이터(repoNames)로 상태를 업데이트하고 이를 UI에 반영합니다 (showModal). 이러한 혼합된 로직은 테스트를 복잡하게 만듭니다. 비즈니스 로직을 테스트하기 위해서는 UI를 함께 로드해야 하기 때문입니다.

  - 분리되지 않은 코드를 테스트하려면, 모킹(mocking) 라이브러리(예: Mockito)를 사용하여 http.Client와 같은 외부 의존성을 모킹해야 합니다. 그러나 이 경우에도, UI 상태의 변화(예: 모달의 표시, setState 호출의 결과)를 검증하는 것은 Flutter 테스트 프레임워크 내에서 처리하기가 어렵습니다. 해당 위젯의 동작을 정확히 시뮬레이션하는 것이 어려울 수 있으므로, 테스트는 간접적인 방식으로 로직을 테스트하게 되고 예를 들어서, 사용자 인터랙션과 결과 UI 상태 등을 검증하게 됩니다.

  - 예시: 데이터 fetching 시 CircularProgressIndicator가 표시되는지 검증

    ```
      void main() {
        group('CommitHeatmap UI Tests', () {
          testWidgets('displays loader when data is being fetched',
              (WidgetTester tester) async {
            await tester
                .pumpWidget(MaterialApp(home: CommitHeatmap(username: "testuser")));

            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          });
        });
      }

### MVVM 패턴 적용

  - MVVM 패턴을 적용하여 비즈니스 로직을 CommitHeatmapViewModel로 분리함으로써, 데이터 처리와 UI 로직을 명확히 분리하고 각각을 독립적으로 테스트할 수 있습니다. 구체적인 데이터 소스나 UI 구성 요소와의 결합 없이 비즈니스 로직의 정확성을 검증합니다.

    ```
          @GenerateMocks([GitHubRepository])
          void main() {
            group('CommitHeatmapViewModel Test', () {
              late MockGitHubRepository mockGitHubRepository;
              late CommitHeatmapViewModel viewModel;

              setUp(() {
                mockGitHubRepository = MockGitHubRepository();
                viewModel = CommitHeatmapViewModel(mockGitHubRepository, "username");
              });

              test('setSelectedRepository should update repository and fetch commits',
                  () async {
                when(mockGitHubRepository.fetchAllCommits(any, any,
                        startOfMonth: anyNamed('startOfMonth'),
                        endOfMonth: anyNamed('endOfMonth')))
                    .thenAnswer((_) async => [
                          CommitInfo(
                              date: DateTime.now(),
                              message: "Initial commit",
                              htmlUrl: 'https://example.com/commit')
                        ]);

                await viewModel.setSelectedRepository("testRepo");

                expect(viewModel.selectedRepository, "testRepo");
                expect(viewModel.commitData.isNotEmpty, true);
              });
            });
          }

## 상태 관리와 Provider

  - 애플리케이션 개발 과정에서 상태 관리는 사용자 인터페이스의 일관성을 유지하게 하고 데이터 흐름을 관리하기 때문에, 굉장히 중요한 요소라 할 수 있습니다. Provider는 Flutter에서 상태 관리와 의존성 주입을 위해 광범위하게 사용되는 라이브러리입니다. Provider는 위젯 트리 구조를 활용하여 상태를 관리하고, 필요한 곳에 데이터를 전달하여 애플리케이션의 다양한 부분에서 필요한 데이터에 쉽게 접근할 수 있도록 돕습니다.

  - CommitChecker는  Main -> Inputpage -> CommitHeatMap 위젯 트리 구조로 되어 있습니다. InputPage에서 Provider를 생성하여 InputPage에서 생성된 상태(사용자가 입력한 GitHub 계정)를 CommitHeatmap에 전달하였습니다.

  - React에서 사용하는 Zustand는 별도의 스토어에서 전역 상태를 관리하고, 훅 형태의 API를 통해 상태를 쉽게 구독하고 업데이트할 수 있습니다. Zustand와 비교해볼 때, Provider는 Flutter의 위젯 트리 구조를 활용한 상태 관리를 하기 때문에, 트리의 깊은 곳에서 상태를 접근할 때는 복잡성이 증가하게 됩니다. 또한 실제 상태의 "전역성"은 위젯 트리 내에서 Provider가 사용되는 범위에 따라 결정됩니다. Provider를 위젯 트리의 루트 근처에 배치하면, 애플리케이션의 대부분의 부분에서 해당 Provider를 통해 상태에 접근할 수 있어 상태가 더 "전역적"이 됩니다. 반면, 특정 위젯 아래에 Provider를 배치하면, 그 위젯과 그 자식 위젯들만이 상태에 접근할 수 있으며, 이는 상태의 범위를 제한합니다.

 - 현재 구조에서 InputPage와 CommitHeatmap만 상태를 공유하고 있지만, 애플리케이션의 규모가 커지면서 더 많은 위젯이 동일한 상태를 공유해야 할 필요가 생길 수 있습니다. 이 경우, Provider를 더 상위 위젯(예: Main)에 배치하는 것이 적합할 수 있습니다. 상태가 공유되어야 하는 위젯의 범위를 고려하여 Provider의 위치를 결정해야 하는 점이 Provider의 특징이자 Zustand와 같은 전역 상태 관리 라이브러리와 비교되는 점인 것 같습니다.

 <br>

# 기술스택

- Front-end:
  - Dart, Flutter, Github API, Provider, Mockito

<br>

# 연락처

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/donghyukkil">
        <img src="https://avatars.githubusercontent.com/u/124029691?v=4" alt="길동혁 프로필" width="100px" height="100px" />
      </a>
    </td>
  </tr>
  <tr>
    <td>
      <ul>
        <li><a href="https://github.com/donghyukkil">길동혁</a></li>
		    <li>asterism90@gmail.com</li>
	    </ul>
    </td>
  </tr>
</table>




